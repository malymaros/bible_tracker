import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
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
  final bool canMarkRead;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
    this.canMarkRead = false,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final book = _book;
    final chapter = ref.watch(_chapterTextProvider(_chapterRef));
    final previous = ChapterCursor.full.previousOf(_chapterRef);
    final next = ChapterCursor.full.nextOf(_chapterRef);

    final isCurrentChapterRead = widget.canMarkRead
        ? (ref.watch(readChaptersProvider).value ?? const {}).contains(
            _chapterRef,
          )
        : false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${book.name} ${_chapterRef.chapterNumber}')),
      floatingActionButton: widget.canMarkRead
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
              backgroundColor: AppColors.goldSoft,
              foregroundColor: AppColors.goldDark,
              icon: Icon(
                isCurrentChapterRead
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
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
                previous: previous,
                next: next,
                isDownloading: _isDownloadingBook,
                onDownloadBook: _downloadBook,
                onOpenSsv: _showSsvUrl,
                onPrevious: () => _goTo(previous),
                onNext: () => _goTo(next),
              );
            }
            return _DownloadedChapterView(
              row: row,
              previous: previous,
              next: next,
              onPrevious: () => _goTo(previous),
              onNext: () => _goTo(next),
            );
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
  final ChapterRef? previous;
  final ChapterRef? next;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DownloadedChapterView({
    required this.row,
    required this.previous,
    required this.next,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const Key('reader-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: AppCard(child: _ChapterHtml(htmlContent: row.htmlContent)),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    key: const Key('reader-previous-button'),
                    onPressed: previous == null ? null : onPrevious,
                    icon: const Icon(Icons.chevron_left),
                    label: Text(l10n.readerPreviousChapter),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppOutlinedButton(
                    key: const Key('reader-next-button'),
                    onPressed: next == null ? null : onNext,
                    icon: const Icon(Icons.chevron_right),
                    label: Text(l10n.readerNextChapter),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingChapterView extends StatelessWidget {
  final BibleBook book;
  final ChapterRef chapterRef;
  final ChapterRef? previous;
  final ChapterRef? next;
  final bool isDownloading;
  final VoidCallback onDownloadBook;
  final VoidCallback onOpenSsv;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MissingChapterView({
    required this.book,
    required this.chapterRef,
    required this.previous,
    required this.next,
    required this.isDownloading,
    required this.onDownloadBook,
    required this.onOpenSsv,
    required this.onPrevious,
    required this.onNext,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    key: const Key('reader-previous-button'),
                    onPressed: previous == null ? null : onPrevious,
                    icon: const Icon(Icons.chevron_left),
                    label: Text(l10n.readerPreviousChapter),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppOutlinedButton(
                    key: const Key('reader-next-button'),
                    onPressed: next == null ? null : onNext,
                    icon: const Icon(Icons.chevron_right),
                    label: Text(l10n.readerNextChapter),
                  ),
                ),
              ],
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
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    if (node is! dom.Element) return null;

    if (node.localName == 'br') {
      return const SizedBox(height: 8);
    }

    final span = _spanForNode(
      context,
      node,
      Theme.of(context).textTheme.bodyLarge,
    );
    final align = node.attributes['align'] == 'center'
        ? TextAlign.center
        : TextAlign.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          fontSize: (style.fontSize ?? 16) * 0.72,
          color: Theme.of(context).colorScheme.primary,
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
