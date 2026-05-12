import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_progress.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';

/// Pure stateless service. Computes [PlanProgress] from a reading plan,
/// its generated schedule, the global read-chapter set, and the current date.
///
/// Only chapters that belong to the plan are counted toward plan progress.
/// Chapters marked as read that are not part of this plan are ignored.
abstract final class PlanProgressCalculator {
  static PlanProgress calculate({
    required ReadingPlan plan,
    required List<PlanDay> days,
    required Set<ChapterRef> readChapters,
    required DateTime today,
  }) {
    final normalizedToday =
        DateTime(today.year, today.month, today.day);

    // All chapters assigned to the plan (no duplicates guaranteed by generator).
    final planChaptersSet = <ChapterRef>{
      for (final d in days) ...d.chapters,
    };
    final totalPlanChapters =
        days.fold<int>(0, (sum, d) => sum + d.chapters.length);

    // Plan chapters that have been read globally.
    final completedPlanChapters =
        readChapters.intersection(planChaptersSet).length;

    // Expected = chapters in days whose scheduled date is on or before today.
    var expectedChaptersByToday = 0;
    for (final day in days) {
      if (!day.scheduledDate.isAfter(normalizedToday)) {
        expectedChaptersByToday += day.chapters.length;
      }
    }

    final aheadBehindChapterCount =
        completedPlanChapters - expectedChaptersByToday;

    return PlanProgress(
      planId: plan.id,
      totalPlanChapters: totalPlanChapters,
      completedPlanChapters: completedPlanChapters,
      expectedChaptersByToday: expectedChaptersByToday,
      aheadBehindChapterCount: aheadBehindChapterCount,
      completionPercent: totalPlanChapters > 0
          ? completedPlanChapters / totalPlanChapters * 100
          : 0.0,
    );
  }
}
