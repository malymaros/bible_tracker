import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/db/tables/color_bookmarks_table.dart';
import 'package:bible_tracker/db/tables/verse_bookmarks_table.dart';
import 'package:drift/drift.dart';

part 'bookmark_dao.g.dart';

/// Favourite verses (`verse_bookmarks`) and the five classic colour
/// bookmarks (`color_bookmarks`).
@DriftAccessor(tables: [VerseBookmarks, ColorBookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase>
    with _$BookmarkDaoMixin {
  BookmarkDao(super.db);

  /// Favourite verses.
  Stream<List<VerseBookmark>> watchAll() {
    return select(verseBookmarks).watch().map(
      (rows) => [
        for (final r in rows)
          VerseBookmark(
            VerseRef(r.bookId, r.chapterNumber, r.verseNumber),
            DateTime.fromMillisecondsSinceEpoch(r.bookmarkedAt),
          ),
      ],
    );
  }

  Expression<bool> _matches($VerseBookmarksTable t, VerseRef ref) =>
      t.bookId.equals(ref.bookId) &
      t.chapterNumber.equals(ref.chapterNumber) &
      t.verseNumber.equals(ref.verseNumber);

  /// Makes [ref] a favourite verse, or no longer one.
  Future<void> toggle(VerseRef ref) async {
    if (await isBookmarked(ref)) {
      await (delete(verseBookmarks)..where((t) => _matches(t, ref))).go();
    } else {
      await into(verseBookmarks).insert(
        VerseBookmarksCompanion(
          bookId: Value(ref.bookId),
          chapterNumber: Value(ref.chapterNumber),
          verseNumber: Value(ref.verseNumber),
          bookmarkedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  /// Whether [ref] is a favourite verse.
  Future<bool> isBookmarked(VerseRef ref) async {
    final row = await (select(
      verseBookmarks,
    )..where((t) => _matches(t, ref))).getSingleOrNull();
    return row != null;
  }

  /// The classic bookmarks that lie somewhere; free colours are absent.
  Stream<List<ColorBookmark>> watchColors() {
    return select(colorBookmarks).watch().map(
      (rows) => [
        for (final r in rows)
          if (_colorByName[r.color] case final color?)
            ColorBookmark(
              color,
              VerseRef(r.bookId, r.chapterNumber, r.verseNumber),
              DateTime.fromMillisecondsSinceEpoch(r.placedAt),
            ),
      ],
    );
  }

  /// Puts the [color] bookmark on [ref], taking it from wherever it was.
  Future<void> placeColor(BookmarkColor color, VerseRef ref) {
    return into(colorBookmarks).insertOnConflictUpdate(
      ColorBookmarksCompanion.insert(
        color: color.name,
        bookId: ref.bookId,
        chapterNumber: ref.chapterNumber,
        verseNumber: ref.verseNumber,
        placedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Takes the [color] bookmark out: the colour is free again.
  Future<void> clearColor(BookmarkColor color) {
    return (delete(
      colorBookmarks,
    )..where((t) => t.color.equals(color.name))).go();
  }

  /// Chapters holding a favourite or a classic bookmark.
  Stream<Set<ChapterRef>> watchBookmarkedChapters() {
    return customSelect(
      'SELECT book_id, chapter_number FROM verse_bookmarks '
      'UNION SELECT book_id, chapter_number FROM color_bookmarks',
      readsFrom: {verseBookmarks, colorBookmarks},
    ).watch().map(
      (rows) => {
        for (final r in rows)
          ChapterRef(r.read<String>('book_id'), r.read<int>('chapter_number')),
      },
    );
  }

  static final _colorByName = {for (final c in BookmarkColor.values) c.name: c};
}
