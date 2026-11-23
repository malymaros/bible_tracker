import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/parsed_chapter.dart';
import 'package:bible_tracker/core/models/reader_context.dart';
import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/core/services/verse_parser.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/features/bible/widgets/verse_chapter_view.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:bible_tracker/shared/providers/reader_providers.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final _chapterTextProvider = FutureProvider.family<ChapterTextRow?, ChapterRef>(
  (ref, chapterRef) {
    return ref.watch(chapterTextDaoProvider).getChapterText(chapterRef);
  },
);

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapterNumber;
  final ReaderContext readerContext;

  /// Verse to scroll to and highlight when the chapter opens (e.g. from a
  /// bookmark or a rosary reference).
  final int? initialVerse;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
    this.readerContext = ReaderContext.books,
    this.initialVerse,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late ChapterRef _chapterRef;
  bool _isDownloadingBook = false;
  double _horizontalDragDistance = 0;
  int? _selectedVerse;
  int? _scrollToVerse;

  // Verse the chapter was opened at: highlighted, without the action panel.
  int? _highlightVerse;

  // The last parse, kept so a rebuild does not parse the same HTML again.
  String? _parsedHtml;
  ParsedChapter? _parsed;

  @override
  void initState() {
    super.initState();
    _chapterRef = ChapterRef(widget.bookId, widget.chapterNumber);
    _scrollToVerse = widget.initialVerse;
    _highlightVerse = widget.initialVerse;
  }

  BibleBook get _book => _bookById(_chapterRef.bookId);

  bool get _isPlan => widget.readerContext == ReaderContext.plan;

  ParsedChapter _parse(String html) {
    if (_parsedHtml != html) {
      _parsedHtml = html;
      _parsed = VerseParser.parse(html);
    }
    return _parsed!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Pin the app bar to its resting colour (dark in dark mode, cream in light)
    // so it does not switch to a lighter surface tone when content scrolls
    // underneath it.
    final appBarColor =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final book = _book;
    final chapter = ref.watch(_chapterTextProvider(_chapterRef));
    final previous = ChapterCursor.full.previousOf(_chapterRef);
    final next = ChapterCursor.full.nextOf(_chapterRef);
    final textView =
        ref.watch(readerTextViewProvider).value ?? ReaderTextView.verses;

    final allRead = _isPlan
        ? (ref.watch(readChaptersProvider).value ?? const <ChapterRef>{})
        : const <ChapterRef>{};
    final bookmarks =
        ref.watch(verseBookmarksProvider).value ?? const <VerseBookmark>[];
    final bookmarkedVerses = {
      for (final b in bookmarks)
        if (b.verse.chapter == _chapterRef) b.verse.verseNumber,
    };

    final isCurrentChapterRead = allRead.contains(_chapterRef);

    final row = chapter.value;
    final parsed = row == null ? null : _parse(row.htmlContent);
    final showVerses =
        textView == ReaderTextView.verses && parsed != null && parsed.isUsable;
    final selected = showVerses ? _selectedVerse : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text('${book.name} ${_chapterRef.chapterNumber}'),
        actions: [
          IconButton(
            key: const Key('reader-text-view-toggle'),
            tooltip: l10n.readerTextViewToggle,
            // Looks the same in both views: the toggle only switches.
            icon: const Icon(Icons.text_fields, color: AppColors.textMuted),
            onPressed: () => _toggleTextView(textView),
          ),
        ],
      ),
      floatingActionButton: _isPlan && selected == null
          ? FloatingActionButton.extended(
              key: const Key('reader-mark-read-fab'),
              onPressed: () async {
                final dao = ref.read(progressDaoProvider);
                if (isCurrentChapterRead) {
                  await dao.markUnread(_chapterRef);
                } else {
                  await dao.markRead(_chapterRef, DateTime.now());
                }
              },
              backgroundColor: isCurrentChapterRead
                  ? AppColors.surfaceMuted.withValues(alpha: 0.75)
                  : AppColors.gold.withValues(alpha: 0.75),
              foregroundColor: isCurrentChapterRead
                  ? AppColors.textMuted
                  : Colors.white,
              icon: Icon(
                isCurrentChapterRead ? Icons.undo : Icons.check_circle_outline,
              ),
              label: Text(
                isCurrentChapterRead
                    ? l10n.readerMarkUnread
                    : l10n.readerMarkRead,
              ),
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('reader-swipe-area'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                _horizontalDragDistance = 0;
              },
              onHorizontalDragUpdate: (details) {
                _horizontalDragDistance += details.delta.dx;
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200 || _horizontalDragDistance < -80) {
                  _goTo(next);
                } else if (velocity > 200 || _horizontalDragDistance > 80) {
                  _goTo(previous);
                }
              },
              child: chapter.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ReaderMessage(
                  title: l10n.readerChapterLoadError,
                  body: error.toString(),
                ),
                data: (row) {
                  if (row == null) {
                    return _MissingChapterView(
                      book: book,
                      chapterRef: _chapterRef,
                      isDownloading: _isDownloadingBook,
                      onDownloadBook: _downloadBook,
                      onOpenSsv: _showSsvUrl,
                    );
                  }
                  if (showVerses) {
                    return VerseChapterView(
                      chapter: parsed,
                      bookmarkedVerses: bookmarkedVerses,
                      selectedVerse: selected ?? _highlightVerse,
                      scrollToVerse: _scrollToVerse,
                      bottomPadding: selected != null ? 240 : 120,
                      onVerseTap: (v) => setState(() {
                        _selectedVerse = _selectedVerse == v ? null : v;
                        _highlightVerse = null;
                      }),
                    );
                  }
                  return _DownloadedChapterView(row: row);
                },
              ),
            ),
          ),
          if (selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _VerseActionPanel(
                title: '${book.name} ${_chapterRef.chapterNumber},$selected',
                text: parsed!.verseText(selected) ?? '',
                isBookmarked: bookmarkedVerses.contains(selected),
                onClose: () => setState(() => _selectedVerse = null),
                onBookmark: () =>
                    _toggleVerseBookmark(selected, bookmarkedVerses),
                onCopy: () => _copyVerse(parsed, selected),
                onShare: () => _shareVerse(parsed, selected),
              ),
            ),
        ],
      ),
    );
  }

  String _citation(int verse) =>
      '${_book.shortName} ${_chapterRef.chapterNumber},$verse';

  void _toggleTextView(ReaderTextView current) {
    final l10n = AppLocalizations.of(context)!;
    final next = current == ReaderTextView.verses
        ? ReaderTextView.original
        : ReaderTextView.verses;
    setReaderTextView(ref, next);
    setState(() => _selectedVerse = null);
    _snack(
      next == ReaderTextView.verses
          ? l10n.readerTextViewVerses
          : l10n.readerTextViewOriginal,
    );
  }

  Future<void> _toggleVerseBookmark(int verse, Set<int> bookmarked) async {
    final l10n = AppLocalizations.of(context)!;
    final wasBookmarked = bookmarked.contains(verse);
    await ref
        .read(bookmarkDaoProvider)
        .toggle(VerseRef.inChapter(_chapterRef, verse));
    _snack(
      wasBookmarked
          ? l10n.verseBookmarkRemoved
          : '${l10n.verseBookmarkAdded} · ${_citation(verse)}',
    );
  }

  Future<void> _copyVerse(ParsedChapter parsed, int verse) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(
      ClipboardData(text: '${parsed.verseText(verse)} (${_citation(verse)})'),
    );
    if (!mounted) return;
    setState(() => _selectedVerse = null);
    _snack('${l10n.verseCopied} · ${_citation(verse)}');
  }

  Future<void> _shareVerse(ParsedChapter parsed, int verse) async {
    await SharePlus.instance.share(
      ShareParams(text: '${parsed.verseText(verse)} (${_citation(verse)})'),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1600),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _goTo(ChapterRef? nextRef) {
    if (nextRef == null) return;
    setState(() {
      _chapterRef = nextRef;
      _selectedVerse = null;
      _scrollToVerse = null;
      _highlightVerse = null;
    });
  }

  Future<void> _downloadBook() async {
    setState(() => _isDownloadingBook = true);
    try {
      await ref.read(downloadServiceProvider).downloadBook(_book).drain<void>();
      ref.invalidate(downloadedChapterCountsProvider);
      ref.invalidate(_chapterTextProvider(_chapterRef));
    } finally {
      if (mounted) {
        setState(() => _isDownloadingBook = false);
      }
    }
  }

  void _showSsvUrl() {
    final url = SsvScraper.buildSsvUrl(_book, _chapterRef.chapterNumber);
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Bottom panel for a tapped verse: reference, its text, and actions.
class _VerseActionPanel extends StatelessWidget {
  final String title;
  final String text;
  final bool isBookmarked;
  final VoidCallback onClose;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _VerseActionPanel({
    required this.title,
    required this.text,
    required this.isBookmarked,
    required this.onClose,
    required this.onBookmark,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      key: const Key('verse-action-panel'),
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('verse-action-close'),
                    tooltip: l10n.readerClose,
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    _VerseActionButton(
                      key: const Key('verse-action-bookmark'),
                      icon: isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      iconColor: AppColors.error,
                      label: isBookmarked
                          ? l10n.verseActionRemoveBookmark
                          : l10n.verseActionBookmark,
                      onTap: onBookmark,
                    ),
                    const SizedBox(width: 10),
                    _VerseActionButton(
                      key: const Key('verse-action-copy'),
                      icon: Icons.copy_outlined,
                      label: l10n.verseActionCopy,
                      onTap: onCopy,
                    ),
                    const SizedBox(width: 10),
                    _VerseActionButton(
                      key: const Key('verse-action-share'),
                      icon: Icons.share_outlined,
                      label: l10n.verseActionShare,
                      onTap: onShare,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _VerseActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.goldDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DownloadedChapterView extends StatefulWidget {
  final ChapterTextRow row;

  const _DownloadedChapterView({required this.row});

  @override
  State<_DownloadedChapterView> createState() => _DownloadedChapterViewState();
}

class _DownloadedChapterViewState extends State<_DownloadedChapterView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbVisibility: const WidgetStatePropertyAll(true),
          thickness: const WidgetStatePropertyAll(4),
          radius: const Radius.circular(999),
          thumbColor: const WidgetStatePropertyAll(AppColors.gold),
          trackColor: WidgetStatePropertyAll(
            AppColors.goldSoft.withValues(alpha: 0.4),
          ),
          trackVisibility: const WidgetStatePropertyAll(true),
          crossAxisMargin: 2,
        ),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            key: const Key('reader-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: _ChapterHtml(htmlContent: widget.row.htmlContent),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingChapterView extends StatelessWidget {
  final BibleBook book;
  final ChapterRef chapterRef;
  final bool isDownloading;
  final VoidCallback onDownloadBook;
  final VoidCallback onOpenSsv;

  const _MissingChapterView({
    required this.book,
    required this.chapterRef,
    required this.isDownloading,
    required this.onDownloadBook,
    required this.onOpenSsv,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.readerChapterNotDownloaded,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${book.name} ${chapterRef.chapterNumber}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              onPressed: isDownloading ? null : onDownloadBook,
              icon: isDownloading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(l10n.bibleDownloadBook),
            ),
            const SizedBox(height: 8),
            AppOutlinedButton(
              onPressed: onOpenSsv,
              icon: const Icon(Icons.open_in_browser),
              label: Text(l10n.readerOpenSsv),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  final String title;
  final String body;

  const _ReaderMessage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ChapterHtml extends StatelessWidget {
  final String htmlContent;

  const _ChapterHtml({required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    final fragment = html_parser.parseFragment(htmlContent);
    final widgets = fragment.nodes
        .map((node) => _widgetForNode(context, node))
        .whereType<Widget>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets.isEmpty ? [Text(fragment.text ?? '')] : widgets,
    );
  }

  Widget? _widgetForNode(BuildContext context, dom.Node node) {
    final readerBodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 20,
      height: 1.8,
      color: AppColors.text,
    );

    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(text, style: readerBodyStyle),
      );
    }
    if (node is! dom.Element) return null;

    if (node.localName == 'br') {
      return const SizedBox(height: 8);
    }

    final span = _spanForNode(context, node, readerBodyStyle);
    final align = node.attributes['align'] == 'center'
        ? TextAlign.center
        : TextAlign.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RichText(textAlign: align, text: span),
    );
  }

  InlineSpan _spanForNode(
    BuildContext context,
    dom.Node node,
    TextStyle? baseStyle,
  ) {
    if (node is dom.Text) {
      return TextSpan(text: _normalizeText(node.text), style: baseStyle);
    }
    if (node is! dom.Element) {
      return const TextSpan();
    }

    var style = baseStyle;
    switch (node.localName) {
      case 'strong':
      case 'b':
        style = style?.copyWith(fontWeight: FontWeight.w700);
      case 'sup':
        style = style?.copyWith(
          fontSize: (style.fontSize ?? 20) * 0.68,
          color: AppColors.textMuted,
        );
      case 'br':
        return const TextSpan(text: '\n');
    }

    return TextSpan(
      style: style,
      children: [
        for (final child in node.nodes) _spanForNode(context, child, style),
      ],
    );
  }

  String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'[ \t\r\n]+'), ' ');
  }
}

BibleBook _bookById(String bookId) {
  return kBibleBooks.firstWhere((book) => book.id == bookId);
}
