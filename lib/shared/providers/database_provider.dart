import 'package:bible_tracker/db/app_database.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'bible_tracker'));
  ref.onDispose(db.close);
  return db;
});
