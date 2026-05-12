import 'package:bible_tracker/core/constants/ssv_constants.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/db/daos/chapter_text_dao.dart';

class DownloadService {
  final SsvScraper _scraper;
  final ChapterTextDao _dao;
  final Duration _requestDelay;

  DownloadService(
    this._scraper,
    this._dao, {
    Duration requestDelay = SsvConstants.requestDelay,
  }) : _requestDelay = requestDelay;

  /// Downloads all chapters of [book] sequentially, skipping chapters that are
  /// already cached in the database.
  ///
  /// Emits one [BookDownloadProgress] event at startup (0/total), after each
  /// chapter (whether skipped or freshly downloaded), and a final event with
  /// [BookDownloadStatus.completed] on success or [BookDownloadStatus.failed]
  /// on error.
  Stream<BookDownloadProgress> downloadBook(BibleBook book) async* {
    final total = book.chapterCount;
    int downloaded = 0;

    yield BookDownloadProgress(
      bookId: book.id,
      downloadedChapters: 0,
      totalChapters: total,
      status: BookDownloadStatus.downloading,
    );

    bool firstRequest = true;

    for (int chapter = 1; chapter <= total; chapter++) {
      final ref = ChapterRef(book.id, chapter);

      final existing = await _dao.getChapterText(ref);
      if (existing != null) {
        downloaded++;
        yield BookDownloadProgress(
          bookId: book.id,
          downloadedChapters: downloaded,
          totalChapters: total,
          status: BookDownloadStatus.downloading,
        );
        continue;
      }

      if (!firstRequest) {
        await Future.delayed(_requestDelay);
      }
      firstRequest = false;

      try {
        final text = await _scraper.fetchChapter(book, chapter);
        await _dao.upsertChapterText(
          ref: ref,
          htmlContent: text.htmlContent,
          plainText: text.plainText,
          sourceUrl: text.sourceUrl,
          parserVersion: text.parserVersion,
          cachedAt: DateTime.now(),
        );
        downloaded++;
        yield BookDownloadProgress(
          bookId: book.id,
          downloadedChapters: downloaded,
          totalChapters: total,
          status: BookDownloadStatus.downloading,
        );
      } catch (e) {
        yield BookDownloadProgress(
          bookId: book.id,
          downloadedChapters: downloaded,
          totalChapters: total,
          status: BookDownloadStatus.failed,
          errorMessage: e.toString(),
        );
        return;
      }
    }

    yield BookDownloadProgress(
      bookId: book.id,
      downloadedChapters: downloaded,
      totalChapters: total,
      status: BookDownloadStatus.completed,
    );
  }
}
