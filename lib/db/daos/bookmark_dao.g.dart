// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_dao.dart';

// ignore_for_file: type=lint
mixin _$BookmarkDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookmarkedChaptersTable get bookmarkedChapters =>
      attachedDatabase.bookmarkedChapters;
  BookmarkDaoManager get managers => BookmarkDaoManager(this);
}

class BookmarkDaoManager {
  final _$BookmarkDaoMixin _db;
  BookmarkDaoManager(this._db);
  $$BookmarkedChaptersTableTableManager get bookmarkedChapters =>
      $$BookmarkedChaptersTableTableManager(
        _db.attachedDatabase,
        _db.bookmarkedChapters,
      );
}
