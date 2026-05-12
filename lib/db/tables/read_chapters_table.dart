import 'package:drift/drift.dart';

@DataClassName('ReadChapterRow')
class ReadChapters extends Table {
  TextColumn get bookId => text()();
  IntColumn get chapterNumber => integer()();
  IntColumn get readAt => integer()();

  @override
  Set<Column> get primaryKey => {bookId, chapterNumber};
}
