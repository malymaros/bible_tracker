import 'package:drift/drift.dart';

/// Bookmarked verses. Replaced `bookmarked_chapters` in schema 3; a chapter
/// bookmark from before became a bookmark on its verse 1.
@DataClassName('VerseBookmarkRow')
class VerseBookmarks extends Table {
  TextColumn get bookId => text()();
  IntColumn get chapterNumber => integer()();
  IntColumn get verseNumber => integer()();
  IntColumn get bookmarkedAt => integer()();

  @override
  Set<Column> get primaryKey => {bookId, chapterNumber, verseNumber};
}
