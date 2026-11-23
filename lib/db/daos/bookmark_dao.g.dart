// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_dao.dart';

// ignore_for_file: type=lint
mixin _$BookmarkDaoMixin on DatabaseAccessor<AppDatabase> {
  $VerseBookmarksTable get verseBookmarks => attachedDatabase.verseBookmarks;
  BookmarkDaoManager get managers => BookmarkDaoManager(this);
}

class BookmarkDaoManager {
  final _$BookmarkDaoMixin _db;
  BookmarkDaoManager(this._db);
  $$VerseBookmarksTableTableManager get verseBookmarks =>
      $$VerseBookmarksTableTableManager(
        _db.attachedDatabase,
        _db.verseBookmarks,
      );
}
