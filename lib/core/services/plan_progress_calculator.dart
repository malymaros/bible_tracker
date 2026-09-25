import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_progress.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/utils/local_date.dart';

/// Pure stateless service. Computes [PlanProgress] from a reading plan,
/// its generated schedule, the global read-chapter set, and the current date.
///
/// Only chapters that belong to the plan are counted toward plan progress.
/// Chapters marked as read that are not part of this plan are ignored.
///
/// Drift is measured in whole schedule days rather than by converting a
/// chapter delta through an average. The plan is balanced by verse count, so
/// chapters per day varies widely and the average matches no real day — a
/// heavy day used to read as several days of drift. Days are also the unit
/// the user acts in: an unfinished day is something to go back and read.
abstract final class PlanProgressCalculator {
  static PlanProgress calculate({
    required ReadingPlan plan,
    required List<PlanDay> days,
    required Set<ChapterRef> readChapters,
    required DateTime today,
  }) {
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // All chapters assigned to the plan (no duplicates guaranteed by generator).
    final planChaptersSet = <ChapterRef>{
      for (final d in days) ...d.chapters,
    };
    final totalPlanChapters =
        days.fold<int>(0, (sum, d) => sum + d.chapters.length);

    // Plan chapters that have been read globally.
    final completedPlanChapters =
        readChapters.intersection(planChaptersSet).length;

    // Chapters in days scheduled on or before today. Kept as a plain
    // statistic — it no longer feeds the ahead/behind figures.
    var expectedChaptersByToday = 0;

    // Past days that still hold unread chapters, and how many chapters that
    // leaves outstanding.
    var unfinishedPastDays = 0;
    var unreadPastChapters = 0;

    // Today's day is not overdue until it is over, so it never counts as
    // drift. It only gates reading ahead: you are not ahead while today is
    // still open.
    var todayComplete = true;

    final futureDays = <PlanDay>[];

    for (final day in days) {
      final scheduled = normalizeToLocalMidnight(day.scheduledDate);
      final unread =
          day.chapters.where((c) => !readChapters.contains(c)).length;

      if (scheduled.isAfter(normalizedToday)) {
        futureDays.add(day);
        continue;
      }

      expectedChaptersByToday += day.chapters.length;

      if (scheduled.isBefore(normalizedToday)) {
        if (unread > 0) {
          unfinishedPastDays++;
          unreadPastChapters += unread;
        }
      } else if (unread > 0) {
        todayComplete = false;
      }
    }

    // Reading ahead is an unbroken run of fully read days starting the day
    // after today. The day that breaks the run still contributes its read
    // chapters, so partial progress is not lost — that is the nuance whole
    // days cannot express. Anything past the break is ignored: a day read far
    // out of order is not a head start.
    var readAheadDays = 0;
    var readAheadChapters = 0;
    if (unfinishedPastDays == 0 && todayComplete) {
      futureDays.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
      for (final day in futureDays) {
        final readInDay = day.chapters.where(readChapters.contains).length;
        readAheadChapters += readInDay;
        if (readInDay < day.chapters.length) break;
        readAheadDays++;
      }
    }

    final behind = unfinishedPastDays > 0;

    return PlanProgress(
      planId: plan.id,
      totalPlanChapters: totalPlanChapters,
      completedPlanChapters: completedPlanChapters,
      expectedChaptersByToday: expectedChaptersByToday,
      aheadBehindChapterCount:
          behind ? -unreadPastChapters : readAheadChapters,
      approximateDaysDelta: behind ? -unfinishedPastDays : readAheadDays,
      completionPercent: totalPlanChapters > 0
          ? completedPlanChapters / totalPlanChapters * 100
          : 0.0,
    );
  }
}
