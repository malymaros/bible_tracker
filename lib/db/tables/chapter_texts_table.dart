import 'package:drift/drift.dart';

@DataClassName('ChapterTextRow')
class ChapterTexts extends Table {
  TextColumn get bookId => text()();
  IntColumn get chapterNumber => integer()();
  TextColumn get htmlContent => text()();
  TextColumn get plainText => text().nullable()();

  /// SSV footnotes (`div.faqs` inner HTML); null for chapters without notes
  /// and for rows cached before schema 4 (parserVersion 1).
  TextColumn get notesHtml => text().nullable()();
  TextColumn get sourceUrl => text()();
  IntColumn get parserVersion => integer()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {bookId, chapterNumber};
}
