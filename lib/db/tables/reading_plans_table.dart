import 'package:drift/drift.dart';

@DataClassName('ReadingPlanRow')
class ReadingPlans extends Table {
  TextColumn get id => text()();
  IntColumn get startDate => integer()();
  IntColumn get totalDays => integer()();
  // JSON-encoded List<String> of book IDs.
  TextColumn get selectedBookIds => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
