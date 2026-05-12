import 'package:drift/drift.dart';

@DataClassName('PlanDayRow')
class PlanDays extends Table {
  TextColumn get planId => text()();
  IntColumn get dayNumber => integer()();
  IntColumn get scheduledDate => integer()();
  // JSON-encoded List<{b: bookId, c: chapterNumber}>.
  TextColumn get chaptersJson => text()();

  @override
  Set<Column> get primaryKey => {planId, dayNumber};
}
