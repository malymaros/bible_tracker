import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:bible_tracker/shared/providers/download_providers.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BibliaScreen extends ConsumerStatefulWidget {
  const BibliaScreen({super.key});

  @override
  ConsumerState<BibliaScreen> createState() => _BibliaScreenState();
}

class _BibliaScreenState extends ConsumerState<BibliaScreen> {
  String? _activeDownloadBookId;
  final Map<String, BookDownloadProgress> _downloadProgressByBook = {};
  final Set<String> _failedBookIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = ref.watch(downloadedChapterCountsProvider).value ?? {};
    final activeBookId = _activeDownloadBookId;

    if (activeBookId != null) {
      ref.listen<AsyncValue<BookDownloadProgress>>(
        downloadBookProvider(activeBookId),
        (_, next) => next.whenData(_handleDownloadProgress),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenBiblia)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            for (final group in _bookGroups)
              _BookGroupSection(
                group: group,
                counts: counts,
                activeBookId: activeBookId,
                progressByBook: _downloadProgressByBook,
                failedBookIds: _failedBookIds,
                onTapBook: _showBookActions,
              ),
          ],
        ),
      ),
    );
  }

  void _handleDownloadProgress(BookDownloadProgress progress) {
    if (!mounted) return;
    setState(() {
      _downloadProgressByBook[progress.bookId] = progress;
      if (progress.status == BookDownloadStatus.failed) {
        _failedBookIds.add(progress.bookId);
        _activeDownloadBookId = null;
      } else {
        _failedBookIds.remove(progress.bookId);
      }

      if (progress.status == BookDownloadStatus.completed &&
          _activeDownloadBookId == progress.bookId) {
        _activeDownloadBookId = null;
      }
    });
  }

  void _showBookActions(BibleBook book, _BookDownloadState state) {
    if (state == _BookDownloadState.downloaded) {
      _showChapterPicker(book);
      return;
    }
    _showDownloadSheet(book, state);
  }

  void _showDownloadSheet(BibleBook book, _BookDownloadState state) {
    final l10n = AppLocalizations.of(context)!;
    final isAnotherBookDownloading =
        _activeDownloadBookId != null && _activeDownloadBookId != book.id;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(book.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(_statusLabel(l10n, state)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isAnotherBookDownloading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        setState(() {
                          _failedBookIds.remove(book.id);
                          _activeDownloadBookId = book.id;
                        });
                      },
                icon: const Icon(Icons.download),
                label: Text(l10n.bibleDownloadBook),
              ),
              if (state == _BookDownloadState.partial ||
                  state == _BookDownloadState.error) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteBookText(book);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.bibleDeleteDownloadedText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showChapterPicker(BibleBook book) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      book.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.bibleDeleteDownloadedText,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteBookText(book);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: book.chapterCount,
                  itemBuilder: (context, index) {
                    final chapter = index + 1;
                    return OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/biblia/reader/${book.id}/$chapter');
                      },
                      child: Text('$chapter'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteBookText(book);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.bibleDeleteDownloadedText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBookText(BibleBook book) async {
    await ref.read(chapterTextDaoProvider).deleteBookChapters(book.id);
    if (!mounted) return;
    setState(() {
      _downloadProgressByBook.remove(book.id);
      _failedBookIds.remove(book.id);
      if (_activeDownloadBookId == book.id) {
        _activeDownloadBookId = null;
      }
    });
  }
}

class _BookGroup {
  final CatholicCategory category;
  final String title;

  const _BookGroup(this.category, this.title);

  List<BibleBook> get books =>
      kBibleBooks.where((book) => book.category == category).toList();
}

const _bookGroups = [
  _BookGroup(CatholicCategory.pentateuch, 'Pentateuch'),
  _BookGroup(CatholicCategory.historicalBooks, 'Historické knihy'),
  _BookGroup(CatholicCategory.wisdomBooks, 'Múdroslovné knihy'),
  _BookGroup(CatholicCategory.propheticBooks, 'Prorocké knihy'),
  _BookGroup(CatholicCategory.gospels, 'Evanjeliá'),
  _BookGroup(CatholicCategory.acts, 'Skutky apoštolov'),
  _BookGroup(CatholicCategory.paulineLetters, 'Pavlove listy'),
  _BookGroup(CatholicCategory.catholicLetters, 'Katolícke listy'),
  _BookGroup(CatholicCategory.revelation, 'Zjavenie'),
];

class _BookGroupSection extends StatelessWidget {
  final _BookGroup group;
  final Map<String, int> counts;
  final String? activeBookId;
  final Map<String, BookDownloadProgress> progressByBook;
  final Set<String> failedBookIds;
  final void Function(BibleBook book, _BookDownloadState state) onTapBook;

  const _BookGroupSection({
    required this.group,
    required this.counts,
    required this.activeBookId,
    required this.progressByBook,
    required this.failedBookIds,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Text(
              group.title,
              key: Key('book-group-${group.category.name}'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final book in books)
            _BookRow(
              book: book,
              state: _stateForBook(book),
              statusLabel: _statusLabel(l10n, _stateForBook(book)),
              onTap: () => onTapBook(book, _stateForBook(book)),
            ),
        ],
      ),
    );
  }

  _BookDownloadState _stateForBook(BibleBook book) {
    final progress = progressByBook[book.id];
    if (activeBookId == book.id &&
        progress?.status != BookDownloadStatus.failed &&
        progress?.status != BookDownloadStatus.completed) {
      return _BookDownloadState.downloading;
    }
    if (failedBookIds.contains(book.id) ||
        progress?.status == BookDownloadStatus.failed) {
      return _BookDownloadState.error;
    }

    final downloaded = counts[book.id] ?? 0;
    if (downloaded >= book.chapterCount) {
      return _BookDownloadState.downloaded;
    }
    if (downloaded > 0) {
      return _BookDownloadState.partial;
    }
    return _BookDownloadState.notDownloaded;
  }
}

class _BookRow extends StatelessWidget {
  final BibleBook book;
  final _BookDownloadState state;
  final String statusLabel;
  final VoidCallback onTap;

  const _BookRow({
    required this.book,
    required this.state,
    required this.statusLabel,
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

    return ListTile(
      key: Key('book-row-${book.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        radius: 18,
        child: Text(book.shortName, textAlign: TextAlign.center),
      ),
      title: Text(book.name),
      subtitle: Text(statusLabel),
      trailing: Icon(icon),
      onTap: onTap,
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
