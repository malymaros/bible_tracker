// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_text_dao.dart';

// ignore_for_file: type=lint
mixin _$ChapterTextDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChapterTextsTable get chapterTexts => attachedDatabase.chapterTexts;
  ChapterTextDaoManager get managers => ChapterTextDaoManager(this);
}

class ChapterTextDaoManager {
  final _$ChapterTextDaoMixin _db;
  ChapterTextDaoManager(this._db);
  $$ChapterTextsTableTableManager get chapterTexts =>
      $$ChapterTextsTableTableManager(_db.attachedDatabase, _db.chapterTexts);
}
