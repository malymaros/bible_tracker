import 'package:drift/drift.dart';

/// Classic bookmarks (schema 5): one row per colour, so a colour can lie on
/// one verse only. `color` is a [BookmarkColor] name. Favourite verses stay
/// in `verse_bookmarks`.
@DataClassName('ColorBookmarkRow')
class ColorBookmarks extends Table {
  TextColumn get color => text()();
  TextColumn get bookId => text()();
  IntColumn get chapterNumber => integer()();
  IntColumn get verseNumber => integer()();
  IntColumn get placedAt => integer()();

  @override
  Set<Column> get primaryKey => {color};
}
