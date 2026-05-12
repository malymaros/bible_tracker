import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/db/tables/chapter_texts_table.dart';
import 'package:drift/drift.dart';

part 'chapter_text_dao.g.dart';

@DriftAccessor(tables: [ChapterTexts])
class ChapterTextDao extends DatabaseAccessor<AppDatabase>
    with _$ChapterTextDaoMixin {
  ChapterTextDao(super.db);

  Future<ChapterTextRow?> getChapterText(ChapterRef ref) {
    return (select(chapterTexts)
          ..where((t) =>
              t.bookId.equals(ref.bookId) &
              t.chapterNumber.equals(ref.chapterNumber)))
        .getSingleOrNull();
  }

  Future<void> upsertChapterText({
    required ChapterRef ref,
    required String htmlContent,
    String? plainText,
    required String sourceUrl,
    required int parserVersion,
    required DateTime cachedAt,
  }) {
    return into(chapterTexts).insertOnConflictUpdate(ChapterTextsCompanion(
      bookId: Value(ref.bookId),
      chapterNumber: Value(ref.chapterNumber),
      htmlContent: Value(htmlContent),
      plainText: Value(plainText),
      sourceUrl: Value(sourceUrl),
      parserVersion: Value(parserVersion),
      cachedAt: Value(cachedAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteBookChapters(String bookId) {
    return (delete(chapterTexts)..where((t) => t.bookId.equals(bookId))).go();
  }

  Future<int> countDownloadedChapters(String bookId) async {
    final countExpr = countAll();
    final query = selectOnly(chapterTexts)
      ..addColumns([countExpr])
      ..where(chapterTexts.bookId.equals(bookId));
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  /// Returns a map of bookId → downloaded chapter count for all books that
  /// have at least one cached chapter.
  Stream<Map<String, int>> watchDownloadedChapterCounts() {
    final bookIdCol = chapterTexts.bookId;
    final countExpr = countAll();
    final query = selectOnly(chapterTexts)
      ..addColumns([bookIdCol, countExpr])
      ..groupBy([bookIdCol]);
    return query.watch().map((rows) => {
          for (final row in rows) row.read(bookIdCol)!: row.read(countExpr)!,
        });
  }
}
