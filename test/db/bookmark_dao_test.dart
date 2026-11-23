import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

// chapter_texts as schema 1 – 3 created it (no notes_html column).
const _chapterTextsV3 =
    'CREATE TABLE chapter_texts (book_id TEXT NOT NULL, '
    'chapter_number INTEGER NOT NULL, html_content TEXT NOT NULL, '
    'plain_text TEXT NULL, source_url TEXT NOT NULL, '
    'parser_version INTEGER NOT NULL, cached_at INTEGER NOT NULL, '
    'PRIMARY KEY (book_id, chapter_number))';

void main() {
  test('toggle adds and removes a verse bookmark', () async {
    final db = _openTestDb();
    addTearDown(db.close);
    const v = VerseRef('gen', 1, 27);

    await db.bookmarkDao.toggle(v);
    expect(await db.bookmarkDao.isBookmarked(v), isTrue);
    expect(await db.bookmarkDao.isBookmarked(const VerseRef('gen', 1, 26)),
        isFalse);

    await db.bookmarkDao.toggle(v);
    expect(await db.bookmarkDao.isBookmarked(v), isFalse);
  });

  test('watchAll lists every bookmarked verse', () async {
    final db = _openTestDb();
    addTearDown(db.close);
    await db.bookmarkDao.toggle(const VerseRef('gen', 1, 1));
    await db.bookmarkDao.toggle(const VerseRef('gen', 1, 3));

    final all = await db.bookmarkDao.watchAll().first;
    expect(all.map((b) => b.verse).toSet(), {
      const VerseRef('gen', 1, 1),
      const VerseRef('gen', 1, 3),
    });
  });

  test('settings store and update a value', () async {
    final db = _openTestDb();
    addTearDown(db.close);
    expect(await db.settingsDao.watchValue('k').first, isNull);
    await db.settingsDao.setValue('k', 'a');
    await db.settingsDao.setValue('k', 'b');
    expect(await db.settingsDao.watchValue('k').first, 'b');
  });

  test('upgrade from schema 2 turns chapter bookmarks into verse 1', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(_chapterTextsV3);
          raw.execute(
            'CREATE TABLE bookmarked_chapters (book_id TEXT NOT NULL, '
            'chapter_number INTEGER NOT NULL, bookmarked_at INTEGER NOT NULL, '
            'PRIMARY KEY (book_id, chapter_number))',
          );
          raw.execute(
            "INSERT INTO bookmarked_chapters VALUES ('eph', 5, 1700000000000)",
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);

    final all = await db.bookmarkDao.watchAll().first;
    expect(all.single.verse, const VerseRef('eph', 5, 1));
    expect(
      all.single.bookmarkedAt,
      DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final old = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'bookmarked_chapters'",
        )
        .get();
    expect(old, isEmpty);
  });
}
