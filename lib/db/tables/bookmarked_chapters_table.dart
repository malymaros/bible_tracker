import 'package:drift/drift.dart';

@DataClassName('BookmarkedChapterRow')
class BookmarkedChapters extends Table {
  TextColumn get bookId => text()();
  IntColumn get chapterNumber => integer()();
  IntColumn get bookmarkedAt => integer()();

  @override
  Set<Column> get primaryKey => {bookId, chapterNumber};
}
