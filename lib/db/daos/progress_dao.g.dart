// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReadChaptersTable get readChapters => attachedDatabase.readChapters;
  ProgressDaoManager get managers => ProgressDaoManager(this);
}

class ProgressDaoManager {
  final _$ProgressDaoMixin _db;
  ProgressDaoManager(this._db);
  $$ReadChaptersTableTableManager get readChapters =>
      $$ReadChaptersTableTableManager(_db.attachedDatabase, _db.readChapters);
}
