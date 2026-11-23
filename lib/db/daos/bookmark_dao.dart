import 'package:bible_tracker/core/models/verse_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/db/tables/verse_bookmarks_table.dart';
import 'package:drift/drift.dart';

part 'bookmark_dao.g.dart';

@DriftAccessor(tables: [VerseBookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase>
    with _$BookmarkDaoMixin {
  BookmarkDao(super.db);

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

  Future<bool> isBookmarked(VerseRef ref) async {
    final row = await (select(
      verseBookmarks,
    )..where((t) => _matches(t, ref))).getSingleOrNull();
    return row != null;
  }
}
