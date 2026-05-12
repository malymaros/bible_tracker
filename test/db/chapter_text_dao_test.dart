import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

// Helper: insert a chapter text with sensible defaults.
Future<void> _insert(
  AppDatabase db,
  ChapterRef ref, {
  String html = '<p>text</p>',
  String? plainText,
  String url = 'https://example.com',
  int parserVersion = 1,
  DateTime? cachedAt,
}) {
  return db.chapterTextDao.upsertChapterText(
    ref: ref,
    htmlContent: html,
    plainText: plainText,
    sourceUrl: url,
    parserVersion: parserVersion,
    cachedAt: cachedAt ?? DateTime(2024, 1, 1),
  );
}

void main() {
  // ── getChapterText ────────────────────────────────────────────────────────

  test('getChapterText returns null for a chapter that was never inserted',
      () async {
    final db = _openTestDb();
    addTearDown(db.close);

    expect(
      await db.chapterTextDao.getChapterText(const ChapterRef('gen', 1)),
      isNull,
    );
  });

  test('getChapterText returns the inserted row', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await _insert(db, ref, html: '<p>Gen 1</p>', url: 'https://ssv.sk/gen/1');

    final row = await db.chapterTextDao.getChapterText(ref);
    expect(row, isNotNull);
    expect(row!.bookId, 'gen');
    expect(row.chapterNumber, 1);
    expect(row.htmlContent, '<p>Gen 1</p>');
    expect(row.sourceUrl, 'https://ssv.sk/gen/1');
    expect(row.plainText, isNull);
  });

  test('nullable plainText is stored and retrieved correctly', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 2);
    await _insert(db, ref, plainText: 'Genesis chapter 2');

    final row = await db.chapterTextDao.getChapterText(ref);
    expect(row!.plainText, 'Genesis chapter 2');
  });

  // ── upsertChapterText ─────────────────────────────────────────────────────

  test('upsertChapterText updates an existing row (conflict on PK)', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await _insert(db, ref, html: '<p>v1</p>', parserVersion: 1);
    await _insert(db, ref, html: '<p>v2</p>', parserVersion: 2);

    final row = await db.chapterTextDao.getChapterText(ref);
    expect(row!.htmlContent, '<p>v2</p>');
    expect(row.parserVersion, 2);
  });

  test('cachedAt is stored as milliseconds and retrieved correctly', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    final ts = DateTime(2024, 6, 15, 12, 0);
    await _insert(db, ref, cachedAt: ts);

    final row = await db.chapterTextDao.getChapterText(ref);
    expect(
      DateTime.fromMillisecondsSinceEpoch(row!.cachedAt),
      ts,
    );
  });

  // ── deleteBookChapters ────────────────────────────────────────────────────

  test('deleteBookChapters removes all chapters for the given book', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    await _insert(db, const ChapterRef('gen', 1));
    await _insert(db, const ChapterRef('gen', 2));
    await _insert(db, const ChapterRef('gen', 3));

    await db.chapterTextDao.deleteBookChapters('gen');

    expect(
      await db.chapterTextDao.getChapterText(const ChapterRef('gen', 1)),
      isNull,
    );
    expect(await db.chapterTextDao.countDownloadedChapters('gen'), 0);
  });

  test('deleteBookChapters leaves other books untouched', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    await _insert(db, const ChapterRef('gen', 1));
    await _insert(db, const ChapterRef('matt', 1));

    await db.chapterTextDao.deleteBookChapters('gen');

    expect(
      await db.chapterTextDao.getChapterText(const ChapterRef('matt', 1)),
      isNotNull,
    );
  });

  test('deleteBookChapters does not delete read progress', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await db.progressDao.markRead(ref, DateTime.now());
    await _insert(db, ref);

    await db.chapterTextDao.deleteBookChapters('gen');

    // Chapter text gone, but read progress intact.
    expect(await db.chapterTextDao.getChapterText(ref), isNull);
    expect(await db.progressDao.isRead(ref), isTrue);
  });

  // ── countDownloadedChapters ───────────────────────────────────────────────

  test('countDownloadedChapters returns 0 before any insert', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    expect(
      await db.chapterTextDao.countDownloadedChapters('gen'),
      0,
    );
  });

  test('countDownloadedChapters returns the correct number after inserts',
      () async {
    final db = _openTestDb();
    addTearDown(db.close);

    await _insert(db, const ChapterRef('gen', 1));
    await _insert(db, const ChapterRef('gen', 2));
    await _insert(db, const ChapterRef('matt', 1)); // different book

    expect(await db.chapterTextDao.countDownloadedChapters('gen'), 2);
    expect(await db.chapterTextDao.countDownloadedChapters('matt'), 1);
  });

  test('countDownloadedChapters stays correct after upsert (no double count)',
      () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await _insert(db, ref);
    await _insert(db, ref); // upsert, not new row

    expect(await db.chapterTextDao.countDownloadedChapters('gen'), 1);
  });

  // ── watchDownloadedChapterCounts ──────────────────────────────────────────

  test('watchDownloadedChapterCounts is empty initially', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    expect(
      await db.chapterTextDao.watchDownloadedChapterCounts().first,
      isEmpty,
    );
  });

  test('watchDownloadedChapterCounts groups chapters by book', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    await _insert(db, const ChapterRef('gen', 1));
    await _insert(db, const ChapterRef('gen', 2));
    await _insert(db, const ChapterRef('matt', 1));

    final counts =
        await db.chapterTextDao.watchDownloadedChapterCounts().first;
    expect(counts, {'gen': 2, 'matt': 1});
  });

  test('watchDownloadedChapterCounts is reactive: emits after insert',
      () async {
    final db = _openTestDb();
    addTearDown(db.close);

    final futureEmission = db.chapterTextDao
        .watchDownloadedChapterCounts()
        .firstWhere((m) => m.isNotEmpty);

    await _insert(db, const ChapterRef('gen', 1));

    expect(await futureEmission, {'gen': 1});
  });

  test('watchDownloadedChapterCounts drops book entry after deleteBookChapters',
      () async {
    final db = _openTestDb();
    addTearDown(db.close);

    await _insert(db, const ChapterRef('gen', 1));

    // Subscribe while DB has data; wait for the first empty map.
    final futureEmission = db.chapterTextDao
        .watchDownloadedChapterCounts()
        .firstWhere((m) => m.isEmpty);
    await db.chapterTextDao.deleteBookChapters('gen');

    expect(await futureEmission, isEmpty);
  });
}
