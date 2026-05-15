import 'package:bible_tracker/db/daos/bookmark_dao.dart';
import 'package:bible_tracker/db/daos/chapter_text_dao.dart';
import 'package:bible_tracker/db/daos/plan_dao.dart';
import 'package:bible_tracker/db/daos/progress_dao.dart';
import 'package:bible_tracker/shared/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final progressDaoProvider = Provider<ProgressDao>((ref) {
  return ref.watch(appDatabaseProvider).progressDao;
});

final planDaoProvider = Provider<PlanDao>((ref) {
  return ref.watch(appDatabaseProvider).planDao;
});

final chapterTextDaoProvider = Provider<ChapterTextDao>((ref) {
  return ref.watch(appDatabaseProvider).chapterTextDao;
});

final bookmarkDaoProvider = Provider<BookmarkDao>((ref) {
  return ref.watch(appDatabaseProvider).bookmarkDao;
});
