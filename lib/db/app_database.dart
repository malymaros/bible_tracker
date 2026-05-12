import 'package:bible_tracker/db/daos/chapter_text_dao.dart';
import 'package:bible_tracker/db/daos/plan_dao.dart';
import 'package:bible_tracker/db/daos/progress_dao.dart';
import 'package:bible_tracker/db/tables/chapter_texts_table.dart';
import 'package:bible_tracker/db/tables/plan_days_table.dart';
import 'package:bible_tracker/db/tables/read_chapters_table.dart';
import 'package:bible_tracker/db/tables/reading_plans_table.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [ReadChapters, ReadingPlans, PlanDays, ChapterTexts],
  daos: [ProgressDao, PlanDao, ChapterTextDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
