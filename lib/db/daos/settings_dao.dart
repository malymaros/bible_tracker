import 'package:bible_tracker/db/app_database.dart';
import 'package:bible_tracker/db/tables/app_settings_table.dart';
import 'package:drift/drift.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Emits the stored value of [key], or null while it was never set.
  Stream<String?> watchValue(String key) {
    return (select(appSettings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> setValue(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }
}
