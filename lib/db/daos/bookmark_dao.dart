import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/db/tables/bookmarked_chapters_table.dart';
import 'package:drift/drift.dart';

part 'bookmark_dao.g.dart';

@DriftAccessor(tables: [BookmarkedChapters])
class BookmarkDao extends DatabaseAccessor<AppDatabase>
    with _$BookmarkDaoMixin {
  BookmarkDao(super.db);

  Stream<Set<ChapterRef>> watchAll() {
    return select(bookmarkedChapters).watch().map(
      (rows) => rows.map((r) => ChapterRef(r.bookId, r.chapterNumber)).toSet(),
    );
  }

  Future<void> toggle(ChapterRef ref) async {
    final exists = await (select(bookmarkedChapters)
          ..where(
            (t) =>
                t.bookId.equals(ref.bookId) &
                t.chapterNumber.equals(ref.chapterNumber),
          ))
        .getSingleOrNull();
    if (exists != null) {
      await (delete(bookmarkedChapters)
            ..where(
              (t) =>
                  t.bookId.equals(ref.bookId) &
                  t.chapterNumber.equals(ref.chapterNumber),
            ))
          .go();
    } else {
      await into(bookmarkedChapters).insert(BookmarkedChaptersCompanion(
        bookId: Value(ref.bookId),
        chapterNumber: Value(ref.chapterNumber),
        bookmarkedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }
  }

  Future<bool> isBookmarked(ChapterRef ref) async {
    final row = await (select(bookmarkedChapters)
          ..where(
            (t) =>
                t.bookId.equals(ref.bookId) &
                t.chapterNumber.equals(ref.chapterNumber),
          ))
        .getSingleOrNull();
    return row != null;
  }
}
