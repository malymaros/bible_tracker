import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  // ── mark / unread ────────────────────────────────────────────────────────

  test('markRead stores the chapter; isRead returns true', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await db.progressDao.markRead(ref, DateTime(2024, 1, 1));

    expect(await db.progressDao.isRead(ref), isTrue);
  });

  test('isRead returns false for a chapter that was never read', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    expect(await db.progressDao.isRead(const ChapterRef('gen', 1)), isFalse);
  });

  test('markUnread removes the chapter; isRead returns false', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await db.progressDao.markRead(ref, DateTime(2024, 1, 1));
    await db.progressDao.markUnread(ref);

    expect(await db.progressDao.isRead(ref), isFalse);
  });

  test('markUnread on an unread chapter is a no-op', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    await db.progressDao.markUnread(const ChapterRef('gen', 1));
    expect(await db.progressDao.isRead(const ChapterRef('gen', 1)), isFalse);
  });

  // ── upsert behaviour ─────────────────────────────────────────────────────
  //
  // markRead is an upsert: a second call with the same ChapterRef updates
  // readAt rather than inserting a duplicate row.

  test('duplicate markRead updates readAt, not inserts a second row', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await db.progressDao.markRead(ref, DateTime(2024, 1, 1, 10));
    await db.progressDao.markRead(ref, DateTime(2024, 1, 1, 20));

    final all = await db.progressDao.watchAllReadChapters().first;
    expect(all, {ref}); // only one entry, no duplicate
  });

  // ── watchAllReadChapters ──────────────────────────────────────────────────

  test('watchAllReadChapters starts empty', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    expect(await db.progressDao.watchAllReadChapters().first, isEmpty);
  });

  test('watchAllReadChapters reflects all marked chapters', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const r1 = ChapterRef('gen', 1);
    const r2 = ChapterRef('gen', 2);
    const r3 = ChapterRef('matt', 1);
    final now = DateTime.now();

    await db.progressDao.markRead(r1, now);
    await db.progressDao.markRead(r2, now);
    await db.progressDao.markRead(r3, now);

    expect(
      await db.progressDao.watchAllReadChapters().first,
      {r1, r2, r3},
    );
  });

  test('watchAllReadChapters is reactive: emits update after markRead',
      () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);

    // Subscribe before the write. firstWhere handles any ordering of the
    // initial-state and post-write emissions.
    final futureEmission = db.progressDao
        .watchAllReadChapters()
        .firstWhere((s) => s.isNotEmpty);

    await db.progressDao.markRead(ref, DateTime.now());

    expect(await futureEmission, {ref});
  });

  test('watchAllReadChapters emits removal after markUnread', () async {
    final db = _openTestDb();
    addTearDown(db.close);

    const ref = ChapterRef('gen', 1);
    await db.progressDao.markRead(ref, DateTime.now());

    // Subscribe while DB has data; wait for the first empty emission.
    final futureEmission = db.progressDao
        .watchAllReadChapters()
        .firstWhere((s) => s.isEmpty);

    await db.progressDao.markUnread(ref);

    expect(await futureEmission, isEmpty);
  });
}
