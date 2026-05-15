import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/shared/providers/dao_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final activePlanProvider = StreamProvider<ReadingPlan?>((ref) {
  return ref.watch(planDaoProvider).watchActivePlan();
});

final planDaysProvider = StreamProvider.family<List<PlanDay>, String>((
  ref,
  planId,
) {
  return ref.watch(planDaoProvider).watchPlanDays(planId);
});

final readChaptersProvider = StreamProvider<Set<ChapterRef>>((ref) {
  return ref.watch(progressDaoProvider).watchAllReadChapters();
});

final todayProvider = Provider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final bookmarkedChaptersProvider = StreamProvider<Set<ChapterRef>>((ref) {
  return ref.watch(bookmarkDaoProvider).watchAll();
});
