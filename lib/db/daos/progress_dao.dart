import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/db/tables/read_chapters_table.dart';
import 'package:drift/drift.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [ReadChapters])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Stream<Set<ChapterRef>> watchAllReadChapters() {
    return select(readChapters).watch().map(
          (rows) =>
              rows.map((r) => ChapterRef(r.bookId, r.chapterNumber)).toSet(),
        );
  }

  /// Inserts the chapter as read. If already read, updates [readAt] (upsert).
  Future<void> markRead(ChapterRef ref, DateTime readAt) {
    return into(readChapters).insertOnConflictUpdate(ReadChaptersCompanion(
      bookId: Value(ref.bookId),
      chapterNumber: Value(ref.chapterNumber),
      readAt: Value(readAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> markUnread(ChapterRef ref) {
    return (delete(readChapters)
          ..where((t) =>
              t.bookId.equals(ref.bookId) &
              t.chapterNumber.equals(ref.chapterNumber)))
        .go();
  }

  Future<bool> isRead(ChapterRef ref) async {
    final row = await (select(readChapters)
          ..where((t) =>
              t.bookId.equals(ref.bookId) &
              t.chapterNumber.equals(ref.chapterNumber)))
        .getSingleOrNull();
    return row != null;
  }
}
