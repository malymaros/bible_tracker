import 'package:drift/drift.dart';

/// Small key/value store for user preferences (e.g. the reader text view).
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
