import 'package:bible_tracker/db/daos/bookmark_dao.dart';
import 'package:bible_tracker/db/daos/chapter_text_dao.dart';
import 'package:bible_tracker/db/daos/plan_dao.dart';
import 'package:bible_tracker/db/daos/progress_dao.dart';
import 'package:bible_tracker/db/daos/settings_dao.dart';
import 'package:bible_tracker/db/tables/app_settings_table.dart';
import 'package:bible_tracker/db/tables/chapter_texts_table.dart';
import 'package:bible_tracker/db/tables/plan_days_table.dart';
import 'package:bible_tracker/db/tables/read_chapters_table.dart';
import 'package:bible_tracker/db/tables/reading_plans_table.dart';
import 'package:bible_tracker/db/tables/verse_bookmarks_table.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ReadChapters,
    ReadingPlans,
    PlanDays,
    ChapterTexts,
    VerseBookmarks,
    AppSettings,
  ],
  daos: [ProgressDao, PlanDao, ChapterTextDao, BookmarkDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(verseBookmarks);
        await m.createTable(appSettings);
        if (from == 2) {
          // Schema 2 bookmarked whole chapters: keep each as its verse 1.
          await customStatement(
            'INSERT OR IGNORE INTO verse_bookmarks '
            '(book_id, chapter_number, verse_number, bookmarked_at) '
            'SELECT book_id, chapter_number, 1, bookmarked_at '
            'FROM bookmarked_chapters',
          );
          await customStatement('DROP TABLE IF EXISTS bookmarked_chapters');
        }
      }
    },
  );
}
