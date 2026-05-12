import 'package:drift/drift.dart';

@DataClassName('ChapterTextRow')
class ChapterTexts extends Table {
  TextColumn get bookId => text()();
  IntColumn get chapterNumber => integer()();
  TextColumn get htmlContent => text()();
  TextColumn get plainText => text().nullable()();
  TextColumn get sourceUrl => text()();
  IntColumn get parserVersion => integer()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {bookId, chapterNumber};
}
