import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/constants/verse_counts.dart';
import 'package:bible_tracker/core/utils/chapter_count_format.dart';
import 'package:bible_tracker/core/utils/verse_count_format.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/reader_context.dart';
import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/core/services/verse_parser.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:bible_tracker/shared/providers/reader_providers.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:bible_tracker/shared/widgets/bookmark_ui.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class BibliaScreen extends ConsumerStatefulWidget {
  const BibliaScreen({super.key});

  @override
  ConsumerState<BibliaScreen> createState() => _BibliaScreenState();
}

class _BibliaScreenState extends ConsumerState<BibliaScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = ref.watch(downloadedChapterCountsProvider).value ?? {};
    final bookmarkedChapters =
        ref.watch(bookmarkedChaptersProvider).value ?? const {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.screenBiblia),
        actions: [
          IconButton(
            key: const Key('biblia-bookmarks-button'),
            icon: const Icon(Icons.bookmark, color: AppColors.error),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _BookmarksListScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              const TestamentHeader(title: 'Starý zákon'),
              for (final group in _otBookGroups)
                _BookGroupSection(
                  group: group,
                  counts: counts,
                  bookmarkedChapters: bookmarkedChapters,
                  onTapBook: _openBook,
                ),
              const TestamentHeader(title: 'Nový zákon'),
              for (final group in _ntBookGroups)
                _BookGroupSection(
                  group: group,
                  counts: counts,
                  bookmarkedChapters: bookmarkedChapters,
                  onTapBook: _openBook,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBook(BibleBook book, _BookDownloadState state) {
    if (state == _BookDownloadState.downloaded) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _BookChaptersScreen(book: book),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _BookDownloadScreen(book: book, initialState: state),
        ),
      );
    }
  }
}

class _BookChaptersScreen extends ConsumerWidget {
  final BibleBook book;

  const _BookChaptersScreen({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookmarkedChapters =
        ref.watch(bookmarkedChaptersProvider).value ?? const {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(book.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              '${formatChapterCount(book.chapterCount)} · '
              '${formatVerseCount(verseCountForBook(book.id))}',
              key: const Key('chapters-screen-summary'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: book.chapterCount,
              itemBuilder: (_, index) {
                final chapter = index + 1;
                final ref = ChapterRef(book.id, chapter);
                final isBookmarked = bookmarkedChapters.contains(ref);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReaderScreen(
                              bookId: book.id,
                              chapterNumber: chapter,
                              readerContext: ReaderContext.books,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$chapter',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              formatVerseCountShort(
                                verseCountForChapter(book.id, chapter),
                              ),
                              key: Key('chapter-verse-count-$chapter'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isBookmarked)
                      const Positioned(top: 4, right: 4, child: _BookmarkDot()),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AppOutlinedButton(
                key: const Key('chapters-screen-delete-button'),
                onPressed: () async {
                  await ref
                      .read(chapterTextDaoProvider)
                      .deleteBookChapters(book.id);
                  if (context.mounted) {
                    ref.invalidate(downloadedChapterCountsProvider);
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  l10n.bibleDeleteDownloadedText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The text of a bookmarked verse for the list, read from the downloaded
/// chapter; null when the chapter is no longer downloaded.
final _verseSnippetProvider = FutureProvider.autoDispose
    .family<String?, VerseRef>((ref, verse) async {
      final row = await ref
          .watch(chapterTextDaoProvider)
          .getChapterText(verse.chapter);
      if (row == null) return null;
      return VerseParser.parse(row.htmlContent).verseText(verse.verseNumber);
    });

/// Bookmarks: favourite verses grouped by book in Bible order (shown
/// first), or the five classic bookmarks, one row per colour.
class _BookmarksListScreen extends ConsumerStatefulWidget {
  const _BookmarksListScreen();

  @override
  ConsumerState<_BookmarksListScreen> createState() =>
      _BookmarksListScreenState();
}

class _BookmarksListScreenState extends ConsumerState<_BookmarksListScreen> {
  bool _classic = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.bookmarksTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _BookmarkTabs(
              classic: _classic,
              favouritesLabel: l10n.bookmarksTabFavourites,
              classicLabel: l10n.bookmarksTabClassic,
              onChanged: (classic) => setState(() => _classic = classic),
            ),
          ),
          Expanded(
            child: _classic
                ? const _ClassicBookmarkList()
                : const _FavouriteBookmarkList(),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTabs extends StatelessWidget {
  final bool classic;
  final String favouritesLabel;
  final String classicLabel;
  final ValueChanged<bool> onChanged;

  const _BookmarkTabs({
    required this.classic,
    required this.favouritesLabel,
    required this.classicLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(Key key, bool on, Color color, String label, bool value) {
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: Material(
            color: on ? AppColors.surface : Colors.transparent,
            elevation: on ? 1 : 0,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              key: key,
              borderRadius: BorderRadius.circular(11),
              onTap: () => onChanged(value),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                        color: on ? AppColors.text : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab(
            const Key('bookmarks-tab-favourites'),
            !classic,
            kFavouriteBookmarkColor,
            favouritesLabel,
            false,
          ),
          const SizedBox(width: 4),
          tab(
            const Key('bookmarks-tab-classic'),
            classic,
            bookmarkColorOf(BookmarkColor.red),
            classicLabel,
            true,
          ),
        ],
      ),
    );
  }
}

/// The five classic bookmarks in colour order; a free one shows "–".
class _ClassicBookmarkList extends ConsumerWidget {
  const _ClassicBookmarkList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = {
      for (final c
          in ref.watch(colorBookmarksProvider).value ?? const <ColorBookmark>[])
        c.color: c.verse,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final color in BookmarkColor.values)
          if (places[color] case final verse?)
            _BookmarkRow(
              book: kBibleBooks.firstWhere((b) => b.id == verse.bookId),
              verse: verse,
              color: bookmarkColorOf(color),
            )
          else
            AppCard(
              key: Key('bookmark-free-${color.name}'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  BookmarkGlyph(color: bookmarkColorOf(color)),
                  const SizedBox(width: 16),
                  const Text(
                    '–',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _FavouriteBookmarkList extends ConsumerWidget {
  const _FavouriteBookmarkList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bookmarks =
        ref.watch(verseBookmarksProvider).value ?? const <VerseBookmark>[];
    final order = {for (final b in kBibleBooks) b.id: b.order};

    final sorted = bookmarks.toList()
      ..sort((a, b) {
        final va = a.verse, vb = b.verse;
        final byBook = order[va.bookId]!.compareTo(order[vb.bookId]!);
        if (byBook != 0) return byBook;
        final byChapter = va.chapterNumber.compareTo(vb.chapterNumber);
        if (byChapter != 0) return byChapter;
        return va.verseNumber.compareTo(vb.verseNumber);
      });

    final children = <Widget>[];
    String? lastBook;
    for (final b in sorted) {
      final book = kBibleBooks.firstWhere((x) => x.id == b.verse.bookId);
      if (book.id != lastBook) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Text(
              book.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
        );
        lastBook = book.id;
      }
      children.add(
        _BookmarkRow(
          book: book,
          verse: b.verse,
          color: kFavouriteBookmarkColor,
        ),
      );
    }

    if (sorted.isEmpty) {
      return Center(
        child: Text(
          l10n.bookmarksEmpty,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: children,
    );
  }
}

class _BookmarkRow extends ConsumerWidget {
  final BibleBook book;
  final VerseRef verse;
  final Color color;

  const _BookmarkRow({
    required this.book,
    required this.verse,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippet = ref.watch(_verseSnippetProvider(verse)).value;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ListTile(
        key: Key(
          'bookmark-row-${verse.bookId}-${verse.chapterNumber}-'
          '${verse.verseNumber}',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: BookmarkGlyph(color: color),
        title: Text(
          '${book.name} ${verse.chapterNumber},${verse.verseNumber}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        subtitle: snippet == null
            ? null
            : Text(
                snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReaderScreen(
              bookId: verse.bookId,
              chapterNumber: verse.chapterNumber,
              initialVerse: verse.verseNumber,
              readerContext: ReaderContext.books,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarkDot extends StatelessWidget {
  const _BookmarkDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BookDownloadScreen extends ConsumerStatefulWidget {
  final BibleBook book;
  final _BookDownloadState initialState;

  const _BookDownloadScreen({required this.book, required this.initialState});

  @override
  ConsumerState<_BookDownloadScreen> createState() =>
      _BookDownloadScreenState();
}

class _BookDownloadScreenState extends ConsumerState<_BookDownloadScreen> {
  late _BookDownloadState _state;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isDownloading) {
      ref.listen<AsyncValue<BookDownloadProgress>>(
        downloadBookProvider(widget.book.id),
        (_, next) {
          next.whenData((progress) {
            if (!mounted) return;
            setState(() {
              if (progress.status == BookDownloadStatus.completed) {
                _state = _BookDownloadState.downloaded;
                _isDownloading = false;
                ref.invalidate(downloadedChapterCountsProvider);
              } else if (progress.status == BookDownloadStatus.failed) {
                _state = _BookDownloadState.error;
                _isDownloading = false;
              } else {
                _state = _BookDownloadState.downloading;
              }
            });
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.book.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BookIconBadge(abbreviation: widget.book.shortName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.book.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(
                    label: _statusLabel(l10n, _state),
                    icon: _statusIcon(_state),
                    color: _statusColor(_state),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_state == _BookDownloadState.downloaded)
              AppPrimaryButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => _BookChaptersScreen(book: widget.book),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text(
                  'Čítať',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              )
            else ...[
              AppPrimaryButton(
                onPressed: _isDownloading ? null : _startDownload,
                icon: _isDownloading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  l10n.bibleDownloadBook,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AppOutlinedButton(
                onPressed: _openOnline,
                icon: const Icon(Icons.open_in_browser),
                label: Text(
                  l10n.readerOpenSsv,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_state == _BookDownloadState.partial ||
                  _state == _BookDownloadState.error) ...[
                const SizedBox(height: 8),
                AppOutlinedButton(
                  onPressed: _deleteText,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    l10n.bibleDeleteDownloadedText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _startDownload() {
    ref.invalidate(downloadBookProvider(widget.book.id));
    setState(() {
      _isDownloading = true;
      _state = _BookDownloadState.downloading;
    });
  }

  void _openOnline() {
    final url = SsvScraper.buildSsvUrl(widget.book, 1);
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _deleteText() async {
    await ref.read(chapterTextDaoProvider).deleteBookChapters(widget.book.id);
    if (!mounted) return;
    setState(() => _state = _BookDownloadState.notDownloaded);
    ref.invalidate(downloadedChapterCountsProvider);
  }
}

class _BookGroup {
  final CatholicCategory category;
  final String title;

  const _BookGroup(this.category, this.title);

  List<BibleBook> get books =>
      kBibleBooks.where((book) => book.category == category).toList();
}

const _otBookGroups = [
  _BookGroup(CatholicCategory.pentateuch, 'Pentateuch'),
  _BookGroup(CatholicCategory.historicalBooks, 'Historické knihy'),
  _BookGroup(CatholicCategory.wisdomBooks, 'Múdroslovné knihy'),
  _BookGroup(CatholicCategory.propheticBooks, 'Prorocké knihy'),
];

const _ntBookGroups = [
  _BookGroup(CatholicCategory.gospels, 'Evanjeliá'),
  _BookGroup(CatholicCategory.acts, 'Skutky apoštolov'),
  _BookGroup(CatholicCategory.paulineLetters, 'Pavlove listy'),
  _BookGroup(CatholicCategory.catholicLetters, 'Katolícke listy'),
  _BookGroup(CatholicCategory.revelation, 'Zjavenie'),
];

class _BookGroupSection extends StatelessWidget {
  final _BookGroup group;
  final Map<String, int> counts;
  final Set<ChapterRef> bookmarkedChapters;
  final void Function(BibleBook book, _BookDownloadState state) onTapBook;

  const _BookGroupSection({
    required this.group,
    required this.counts,
    required this.bookmarkedChapters,
    required this.onTapBook,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final books = group.books;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            key: Key('book-group-${group.category.name}'),
            title: group.title,
          ),
          for (final book in books)
            _BookRow(
              book: book,
              state: _stateForBook(book),
              statusLabel: _statusLabel(l10n, _stateForBook(book)),
              hasBookmark: bookmarkedChapters.any((r) => r.bookId == book.id),
              onTap: () => onTapBook(book, _stateForBook(book)),
            ),
        ],
      ),
    );
  }

  _BookDownloadState _stateForBook(BibleBook book) {
    final downloaded = counts[book.id] ?? 0;
    if (downloaded >= book.chapterCount) return _BookDownloadState.downloaded;
    if (downloaded > 0) return _BookDownloadState.partial;
    return _BookDownloadState.notDownloaded;
  }
}

class _BookRow extends StatelessWidget {
  final BibleBook book;
  final _BookDownloadState state;
  final String statusLabel;
  final bool hasBookmark;
  final VoidCallback onTap;

  const _BookRow({
    required this.book,
    required this.state,
    required this.statusLabel,
    required this.hasBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      _BookDownloadState.notDownloaded => Icons.cloud_download_outlined,
      _BookDownloadState.partial => Icons.downloading,
      _BookDownloadState.downloading => Icons.sync,
      _BookDownloadState.downloaded => Icons.check_circle_outline,
      _BookDownloadState.error => Icons.error_outline,
    };

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ListTile(
        key: Key('book-row-${book.id}'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: BookIconBadge(abbreviation: book.shortName),
        title: book.isDeuterocanonical
            ? RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${book.name} ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const TextSpan(
                      text: '✝',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                book.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              label: statusLabel,
              icon: icon,
              color: _statusColor(state),
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBookmark)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.bookmark, color: AppColors.error, size: 18),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

enum _BookDownloadState {
  notDownloaded,
  partial,
  downloading,
  downloaded,
  error,
}

String _statusLabel(AppLocalizations l10n, _BookDownloadState state) {
  return switch (state) {
    _BookDownloadState.notDownloaded => l10n.bibleStatusNotDownloaded,
    _BookDownloadState.partial => l10n.bibleStatusPartial,
    _BookDownloadState.downloading => l10n.bibleStatusDownloading,
    _BookDownloadState.downloaded => l10n.bibleStatusDownloaded,
    _BookDownloadState.error => l10n.bibleStatusError,
  };
}

IconData _statusIcon(_BookDownloadState state) {
  return switch (state) {
    _BookDownloadState.notDownloaded => Icons.cloud_download_outlined,
    _BookDownloadState.partial => Icons.downloading,
    _BookDownloadState.downloading => Icons.sync,
    _BookDownloadState.downloaded => Icons.check_circle_outline,
    _BookDownloadState.error => Icons.error_outline,
  };
}

Color _statusColor(_BookDownloadState state) {
  return switch (state) {
    _BookDownloadState.downloaded => AppColors.goldDark,
    _BookDownloadState.error => AppColors.error,
    _BookDownloadState.downloading => AppColors.goldDark,
    _BookDownloadState.partial => AppColors.goldDark,
    _BookDownloadState.notDownloaded => AppColors.textMuted,
  };
}
