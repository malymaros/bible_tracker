import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/book_download_progress.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/services/download_service.dart';
import 'package:bible_tracker/core/services/ssv_scraper.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _testBook = BibleBook(
  id: 'test',
  name: 'Test Book',
  shortName: 'Tst',
  order: 999,
  testament: Testament.newTestament,
  category: CatholicCategory.paulineLetters,
  chapterCount: 3,
  isDeuterocanonical: false,
  ssvSlug: 'test-book',
);

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

Future<void> _insertCachedChapter(AppDatabase db, int chapter) {
  return db.chapterTextDao.upsertChapterText(
    ref: ChapterRef(_testBook.id, chapter),
    htmlContent: '<p>Cached $chapter</p>',
    plainText: 'Cached $chapter',
    sourceUrl: 'https://example.test/cached/$chapter',
    parserVersion: 1,
    cachedAt: DateTime(2026, 1, chapter),
  );
}

String _chapterHtml(int chapter) {
  return '<html><body>'
      '<div class="ssv-bb-module"><div class="wrapper">'
      '<div class="inbox"><p>Downloaded chapter $chapter.</p></div>'
      '</div></div>'
      '</body></html>';
}

DownloadService _serviceWithClient(AppDatabase db, MockClient client) {
  return DownloadService(
    SsvScraper(client),
    db.chapterTextDao,
    requestDelay: Duration.zero,
  );
}

void main() {
  test('download skips cached chapters', () async {
    final db = _openTestDb();
    addTearDown(db.close);
    await _insertCachedChapter(db, 2);

    final requestedPaths = <String>[];
    final service = _serviceWithClient(
      db,
      MockClient((request) async {
        requestedPaths.add(request.url.path);
        final chapter = int.parse(
          request.url.pathSegments[4].replaceAll('.xhtml', ''),
        );
        return http.Response(_chapterHtml(chapter), 200);
      }),
    );

    await service.downloadBook(_testBook).drain<void>();

    expect(requestedPaths, [
      '/biblia/kniha/test-book/kapitola/1.xhtml',
      '/biblia/kniha/test-book/kapitola/3.xhtml',
    ]);
    expect(await db.chapterTextDao.countDownloadedChapters(_testBook.id), 3);
    expect(
      (await db.chapterTextDao.getChapterText(
        ChapterRef(_testBook.id, 2),
      ))!.plainText,
      'Cached 2',
    );
  });

  test('download emits sequential progress updates', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final service = _serviceWithClient(
      db,
      MockClient((request) async {
        final chapter = int.parse(
          request.url.pathSegments[4].replaceAll('.xhtml', ''),
        );
        return http.Response(_chapterHtml(chapter), 200);
      }),
    );

    final progress = await service.downloadBook(_testBook).toList();

    expect(progress.map((p) => p.downloadedChapters), [0, 1, 2, 3, 3]);
    expect(progress.map((p) => p.totalChapters), everyElement(3));
    expect(progress.map((p) => p.bookId), everyElement(_testBook.id));
    expect(
      progress.take(4).map((p) => p.status),
      everyElement(BookDownloadStatus.downloading),
    );
  });

  test('final status is completed after all chapters are downloaded', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final service = _serviceWithClient(
      db,
      MockClient((request) async {
        final chapter = int.parse(
          request.url.pathSegments[4].replaceAll('.xhtml', ''),
        );
        return http.Response(_chapterHtml(chapter), 200);
      }),
    );

    final progress = await service.downloadBook(_testBook).toList();

    expect(progress.last.status, BookDownloadStatus.completed);
    expect(progress.last.downloadedChapters, _testBook.chapterCount);
    expect(progress.last.errorMessage, isNull);
  });

  test('download emits failed progress when a chapter fails', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final service = _serviceWithClient(
      db,
      MockClient((request) async {
        final chapter = int.parse(
          request.url.pathSegments[4].replaceAll('.xhtml', ''),
        );
        if (chapter == 2) {
          return http.Response('Server Error', 500);
        }
        return http.Response(_chapterHtml(chapter), 200);
      }),
    );

    final progress = await service.downloadBook(_testBook).toList();

    expect(progress.last.status, BookDownloadStatus.failed);
    expect(progress.last.downloadedChapters, 1);
    expect(progress.last.errorMessage, contains('SsvHttpException'));
    expect(await db.chapterTextDao.countDownloadedChapters(_testBook.id), 1);
  });
}
