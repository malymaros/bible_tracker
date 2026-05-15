import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/reader_context.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/core/utils/chapter_cursor.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
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

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
    this.readerContext = ReaderContext.books,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late ChapterRef _chapterRef;
  bool _isDownloadingBook = false;
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _chapterRef = ChapterRef(widget.bookId, widget.chapterNumber);
  }

  BibleBook get _book => _bookById(_chapterRef.bookId);

  bool get _isBooks => widget.readerContext == ReaderContext.books;
  bool get _isPlan => widget.readerContext == ReaderContext.plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final book = _book;
    final chapter = ref.watch(_chapterTextProvider(_chapterRef));
    final previous = ChapterCursor.full.previousOf(_chapterRef);
    final next = ChapterCursor.full.nextOf(_chapterRef);

    final allRead = _isPlan
        ? (ref.watch(readChaptersProvider).value ?? const <ChapterRef>{})
        : const <ChapterRef>{};
    final allBookmarked = _isBooks
        ? (ref.watch(bookmarkedChaptersProvider).value ?? const <ChapterRef>{})
        : const <ChapterRef>{};

    final isCurrentChapterRead = allRead.contains(_chapterRef);
    final isCurrentChapterBookmarked = allBookmarked.contains(_chapterRef);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${book.name} ${_chapterRef.chapterNumber}'),
        actions: [
          if (_isBooks)
            IconButton(
              key: const Key('reader-bookmark-button'),
              icon: Icon(
                isCurrentChapterBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: isCurrentChapterBookmarked
                    ? AppColors.error
                    : AppColors.textMuted,
              ),
              onPressed: () =>
                  ref.read(bookmarkDaoProvider).toggle(_chapterRef),
            ),
        ],
      ),
      floatingActionButton: _isPlan
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
      body: GestureDetector(
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
            return _DownloadedChapterView(row: row);
          },
        ),
      ),
    );
  }

  void _goTo(ChapterRef? nextRef) {
    if (nextRef == null) return;
    setState(() {
      _chapterRef = nextRef;
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

class _DownloadedChapterView extends StatelessWidget {
  final ChapterTextRow row;

  const _DownloadedChapterView({required this.row});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('reader-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: _ChapterHtml(htmlContent: row.htmlContent),
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
