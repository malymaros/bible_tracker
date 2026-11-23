import 'dart:io';

import 'package:bible_tracker/core/constants/ssv_constants.dart';
import 'package:bible_tracker/core/models/chapter_text.dart';
import 'package:http/http.dart' as http;
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/db/daos/chapter_text_dao.dart';

class DownloadService {
  final SsvScraper _scraper;
  final ChapterTextDao _dao;
  final Duration _requestDelay;

  final List<Duration> _retryDelays;

  DownloadService(
    this._scraper,
    this._dao, {
    Duration requestDelay = SsvConstants.requestDelay,
    List<Duration> retryDelays = SsvConstants.retryDelays,
  }) : _requestDelay = requestDelay,
       _retryDelays = retryDelays;

  /// biblia.ssv.sk answers HTTP 429 when asked too often (about 80 quick
  /// requests in a row) and sometimes drops a connection. Both pass after a
  /// pause, so the chapter is fetched again after each delay in
  /// [_retryDelays]; any other error, or running out of retries, fails.
  Future<ChapterText> _fetchWithRetry(BibleBook book, int chapter) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _scraper.fetchChapter(book, chapter);
      } catch (e) {
        final retryable =
            e is http.ClientException ||
            e is SocketException ||
            (e is SsvHttpException &&
                (e.message.contains('HTTP 429') ||
                    e.message.contains('HTTP 503')));
        if (!retryable || attempt >= _retryDelays.length) rethrow;
        await Future<void>.delayed(_retryDelays[attempt]);
      }
    }
  }

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
        final text = await _fetchWithRetry(book, chapter);
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
