import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_progress.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/services/plan_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared test fixture
//
// Plan: 3 days, 3 chapters per day (Gen 1–9), starting 2024-01-01.
//
//   Day 1 (Jan 1): Gen 1, Gen 2, Gen 3
//   Day 2 (Jan 2): Gen 4, Gen 5, Gen 6
//   Day 3 (Jan 3): Gen 7, Gen 8, Gen 9
//   totalPlanChapters = 9
// ---------------------------------------------------------------------------

const _planId = 'test-plan';

final _plan = ReadingPlan(
  id: _planId,
  startDate: DateTime(2024, 1, 1),
  totalDays: 3,
  selectedBookIds: ['gen'],
  createdAt: DateTime(2024, 1, 1),
);

final _days = [
  PlanDay(
    planId: _planId,
    dayNumber: 1,
    scheduledDate: DateTime(2024, 1, 1),
    chapters: [
      const ChapterRef('gen', 1),
      const ChapterRef('gen', 2),
      const ChapterRef('gen', 3),
    ],
  ),
  PlanDay(
    planId: _planId,
    dayNumber: 2,
    scheduledDate: DateTime(2024, 1, 2),
    chapters: [
      const ChapterRef('gen', 4),
      const ChapterRef('gen', 5),
      const ChapterRef('gen', 6),
    ],
  ),
  PlanDay(
    planId: _planId,
    dayNumber: 3,
    scheduledDate: DateTime(2024, 1, 3),
    chapters: [
      const ChapterRef('gen', 7),
      const ChapterRef('gen', 8),
      const ChapterRef('gen', 9),
    ],
  ),
];

/// All 9 plan chapters.
final _allPlanChapters = <ChapterRef>{
  for (var i = 1; i <= 9; i++) ChapterRef('gen', i),
};

/// Gen 1..[n], i.e. the first [n] chapters of the schedule in order.
Set<ChapterRef> _firstChapters(int n) => {
      for (var i = 1; i <= n; i++) ChapterRef('gen', i),
    };

PlanProgress _calc({
  required DateTime today,
  Set<ChapterRef> readChapters = const {},
}) =>
    PlanProgressCalculator.calculate(
      plan: _plan,
      days: _days,
      readChapters: readChapters,
      today: today,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PlanProgressCalculator — plan totals', () {
    late final progress = _calc(today: DateTime(2024, 1, 1));

    test('planId is propagated', () => expect(progress.planId, _planId));
    test('totalPlanChapters is 9', () => expect(progress.totalPlanChapters, 9));
  });

  // ── Before plan starts ──────────────────────────────────────────────────

  group('before plan start date', () {
    late final progress = _calc(today: DateTime(2023, 12, 31));

    test('expectedChaptersByToday is 0', () {
      expect(progress.expectedChaptersByToday, 0);
    });

    test('completedPlanChapters is 0', () {
      expect(progress.completedPlanChapters, 0);
    });

    test('aheadBehindChapterCount is 0', () {
      expect(progress.aheadBehindChapterCount, 0);
    });

    test('approximateDaysDelta is 0', () {
      expect(progress.approximateDaysDelta, 0);
    });

    test('isOnTrack is true', () => expect(progress.isOnTrack, isTrue));
    test('isAhead is false', () => expect(progress.isAhead, isFalse));
    test('isBehind is false', () => expect(progress.isBehind, isFalse));
  });

  // ── Today is never overdue ──────────────────────────────────────────────
  //
  // The whole point of the day-based model: an unread today is the ordinary
  // state for most of the day, not drift.

  group("today's unread chapters are not drift", () {
    group('on plan start date (Jan 1, nothing read)', () {
      late final progress = _calc(today: DateTime(2024, 1, 1));

      test('expectedChaptersByToday still reports day 1 chapters', () {
        expect(progress.expectedChaptersByToday, 3);
      });

      test('completedPlanChapters is 0', () {
        expect(progress.completedPlanChapters, 0);
      });

      test('approximateDaysDelta is 0', () {
        expect(progress.approximateDaysDelta, 0);
      });

      test('aheadBehindChapterCount is 0', () {
        expect(progress.aheadBehindChapterCount, 0);
      });

      test('isOnTrack is true', () => expect(progress.isOnTrack, isTrue));
    });

    test('finishing today leaves you on track, not ahead', () {
      final progress =
          _calc(today: DateTime(2024, 1, 1), readChapters: _firstChapters(3));
      expect(progress.completedPlanChapters, 3);
      expect(progress.approximateDaysDelta, 0);
      expect(progress.aheadBehindChapterCount, 0);
      expect(progress.isOnTrack, isTrue);
    });

    test('past days done and today untouched is on track', () {
      // Jan 2: day 1 fully read, day 2 (today) not started.
      final progress =
          _calc(today: DateTime(2024, 1, 2), readChapters: _firstChapters(3));
      expect(progress.approximateDaysDelta, 0);
      expect(progress.isOnTrack, isTrue);
    });

    test('a half-finished today is still on track', () {
      // Jan 2: day 1 done, 1 of day 2's 3 chapters read.
      final progress =
          _calc(today: DateTime(2024, 1, 2), readChapters: _firstChapters(4));
      expect(progress.approximateDaysDelta, 0);
      expect(progress.isOnTrack, isTrue);
    });
  });

  // ── Behind: unfinished past days ────────────────────────────────────────

  group('behind is counted as unfinished past days', () {
    test('one untouched past day is -1 day / -3 chapters', () {
      final progress = _calc(today: DateTime(2024, 1, 2));
      expect(progress.approximateDaysDelta, -1);
      expect(progress.aheadBehindChapterCount, -3);
      expect(progress.isBehind, isTrue);
      expect(progress.isAhead, isFalse);
      expect(progress.isOnTrack, isFalse);
    });

    test('two untouched past days are -2 days / -6 chapters', () {
      final progress = _calc(today: DateTime(2024, 1, 3));
      expect(progress.approximateDaysDelta, -2);
      expect(progress.aheadBehindChapterCount, -6);
    });

    test('a partly read past day counts as a whole day, 1 chapter short', () {
      // Jan 2: Gen 1–2 read, Gen 3 still missing from day 1.
      final progress =
          _calc(today: DateTime(2024, 1, 2), readChapters: _firstChapters(2));
      expect(progress.approximateDaysDelta, -1);
      expect(progress.aheadBehindChapterCount, -1);
      expect(progress.isBehind, isTrue);
    });

    test('a past rest outweighs anything read ahead', () {
      // Jan 2: day 1 untouched, day 3 fully read.
      final progress = _calc(
        today: DateTime(2024, 1, 3),
        readChapters: {
          const ChapterRef('gen', 4),
          const ChapterRef('gen', 5),
          const ChapterRef('gen', 6),
        },
      );
      expect(progress.approximateDaysDelta, -1); // day 1 only
      expect(progress.aheadBehindChapterCount, -3);
    });
  });

  // ── Ahead: an unbroken run of future days ───────────────────────────────

  group('ahead is counted as fully read days after today', () {
    test('one full future day is +1 day / +3 chapters', () {
      // Jan 1: days 1 and 2 read.
      final progress =
          _calc(today: DateTime(2024, 1, 1), readChapters: _firstChapters(6));
      expect(progress.approximateDaysDelta, 1);
      expect(progress.aheadBehindChapterCount, 3);
      expect(progress.isAhead, isTrue);
    });

    test('two full future days are +2 days / +6 chapters', () {
      final progress = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: _allPlanChapters,
      );
      expect(progress.approximateDaysDelta, 2);
      expect(progress.aheadBehindChapterCount, 6);
    });

    test('partial progress into the next day shows as chapters, not a day', () {
      // Jan 1: day 1 done plus Gen 4–5, i.e. 2 of day 2's 3 chapters.
      final progress =
          _calc(today: DateTime(2024, 1, 1), readChapters: _firstChapters(5));
      expect(progress.approximateDaysDelta, 0);
      expect(progress.aheadBehindChapterCount, 2);
      expect(progress.isOnTrack, isTrue);
    });

    test('a day read out of order past a gap does not count', () {
      // Jan 1: day 1 done, day 3 done, day 2 skipped.
      final progress = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: {
          ..._firstChapters(3),
          const ChapterRef('gen', 7),
          const ChapterRef('gen', 8),
          const ChapterRef('gen', 9),
        },
      );
      expect(progress.approximateDaysDelta, 0);
      expect(progress.aheadBehindChapterCount, 0);
    });

    test('reading ahead while today is unfinished does not count', () {
      // Jan 1: day 1 untouched, day 2 fully read.
      final progress = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: {
          const ChapterRef('gen', 4),
          const ChapterRef('gen', 5),
          const ChapterRef('gen', 6),
        },
      );
      expect(progress.approximateDaysDelta, 0);
      expect(progress.aheadBehindChapterCount, 0);
      expect(progress.isOnTrack, isTrue);
    });
  });

  // ── Heavy days no longer inflate the drift ──────────────────────────────
  //
  // Regression for the original complaint. The generator balances days by
  // verse count, so chapters per day varies; a day carrying twice the average
  // chapter count used to read as two days of drift the moment it went
  // unread, because the delta was converted through totalChapters/totalDays.

  group('a heavy day does not inflate the drift', () {
    const heavyPlanId = 'heavy-plan';

    // 4 days, 12 chapters → average 3 chapters/day, but today holds 6.
    final heavyPlan = ReadingPlan(
      id: heavyPlanId,
      startDate: DateTime(2024, 1, 1),
      totalDays: 4,
      selectedBookIds: ['gen'],
      createdAt: DateTime(2024, 1, 1),
    );
    final heavyDays = [
      for (var d = 0; d < 3; d++)
        PlanDay(
          planId: heavyPlanId,
          dayNumber: d + 1,
          scheduledDate: DateTime(2024, 1, 1 + d),
          chapters: [
            ChapterRef('gen', d * 2 + 1),
            ChapterRef('gen', d * 2 + 2),
          ],
        ),
      PlanDay(
        planId: heavyPlanId,
        dayNumber: 4,
        scheduledDate: DateTime(2024, 1, 4),
        chapters: [for (var i = 7; i <= 12; i++) ChapterRef('gen', i)],
      ),
    ];

    PlanProgress heavyCalc(Set<ChapterRef> read) =>
        PlanProgressCalculator.calculate(
          plan: heavyPlan,
          days: heavyDays,
          readChapters: read,
          // Day 4 — the 6-chapter day.
          today: DateTime(2024, 1, 4),
        );

    test('6 unread chapters on today read as on track, not 2 days behind', () {
      final progress = heavyCalc(_firstChapters(6)); // days 1–3 done
      expect(progress.approximateDaysDelta, 0);
      expect(progress.aheadBehindChapterCount, 0);
      expect(progress.isOnTrack, isTrue);
    });

    test('finishing the heavy day is still on track', () {
      final progress = heavyCalc(_firstChapters(12));
      expect(progress.approximateDaysDelta, 0);
      expect(progress.isOnTrack, isTrue);
    });

    test('a light unfinished past day is exactly one day behind', () {
      // Day 1 (2 chapters) untouched, days 2–3 done.
      final progress = heavyCalc({
        for (var i = 3; i <= 6; i++) ChapterRef('gen', i),
      });
      expect(progress.approximateDaysDelta, -1);
      expect(progress.aheadBehindChapterCount, -2);
    });
  });

  // ── After plan end ──────────────────────────────────────────────────────

  group('after plan end date (Jan 5)', () {
    test('expectedChaptersByToday equals totalPlanChapters', () {
      final progress = _calc(today: DateTime(2024, 1, 5));
      expect(progress.expectedChaptersByToday, 9);
    });

    test('completing all chapters after end → on track', () {
      final progress = _calc(
        today: DateTime(2024, 1, 5),
        readChapters: _allPlanChapters,
      );
      expect(progress.completedPlanChapters, 9);
      expect(progress.approximateDaysDelta, 0);
      expect(progress.aheadBehindChapterCount, 0);
      expect(progress.isOnTrack, isTrue);
    });

    test('having read nothing after end → 3 days / 9 chapters behind', () {
      final progress = _calc(today: DateTime(2024, 1, 5));
      expect(progress.approximateDaysDelta, -3);
      expect(progress.aheadBehindChapterCount, -9);
      expect(progress.isBehind, isTrue);
    });
  });

  // ── Chapters outside the plan ───────────────────────────────────────────

  group('chapters read outside the plan do not count', () {
    // The plan covers Gen 1–9.
    late final progress = _calc(
      today: DateTime(2024, 1, 2),
      readChapters: {
        const ChapterRef('gen', 10), // outside plan
        const ChapterRef('gen', 11), // outside plan
        const ChapterRef('matt', 1), // outside plan
      },
    );

    test('completedPlanChapters is 0', () {
      expect(progress.completedPlanChapters, 0);
    });

    test('day 1 still counts as an unfinished past day', () {
      expect(progress.approximateDaysDelta, -1);
      expect(progress.aheadBehindChapterCount, -3);
      expect(progress.isBehind, isTrue);
    });
  });

  group('mix of plan and non-plan chapters read', () {
    // Read Gen 1 (in plan) + Gen 50 (not in plan), on Jan 2.
    late final progress = _calc(
      today: DateTime(2024, 1, 2),
      readChapters: {
        const ChapterRef('gen', 1), // in plan, day 1
        const ChapterRef('gen', 50), // NOT in plan
      },
    );

    test('completedPlanChapters counts only plan chapters', () {
      expect(progress.completedPlanChapters, 1);
    });

    test('only the plan chapters missing from day 1 are outstanding', () {
      expect(progress.approximateDaysDelta, -1);
      expect(progress.aheadBehindChapterCount, -2); // Gen 2 and Gen 3
    });
  });

  // ── Completion percent ───────────────────────────────────────────────────

  group('completionPercent', () {
    test('0% when nothing read', () {
      final progress = _calc(today: DateTime(2024, 1, 1));
      expect(progress.completionPercent, 0.0);
    });

    test('100% when all plan chapters read', () {
      final progress = _calc(
        today: DateTime(2024, 1, 3),
        readChapters: _allPlanChapters,
      );
      expect(progress.completionPercent, 100.0);
    });

    test('partial completion calculates correct percent', () {
      final progress =
          _calc(today: DateTime(2024, 1, 2), readChapters: _firstChapters(3));
      expect(progress.completionPercent, closeTo(3 / 9 * 100, 0.001));
    });
  });

  // ── today time component stripped ────────────────────────────────────────

  group('today time component is stripped', () {
    test('Jan 1 at 23:59:59 is treated as Jan 1', () {
      final progress = _calc(today: DateTime(2024, 1, 1, 23, 59, 59));
      expect(progress.expectedChaptersByToday, 3); // day 1 included
      expect(progress.approximateDaysDelta, 0); // day 1 is not a past day
    });

    test('Jan 2 at 00:00:01 is treated as Jan 2', () {
      final progress = _calc(today: DateTime(2024, 1, 2, 0, 0, 1));
      expect(progress.expectedChaptersByToday, 6);
      expect(progress.approximateDaysDelta, -1); // day 1 is now past
    });
  });

  // ── scheduledDate time component stripped ────────────────────────────────
  //
  // A DST transition used to leave scheduledDate at 01:00 (spring forward) or
  // at 23:00 of the previous day (fall back). Either one misclassified a day
  // as past or future and threw the drift off by a whole day.

  group('scheduledDate time component is stripped', () {
    List<PlanDay> daysShiftedBy(Duration offset) => [
          for (final d in _days)
            PlanDay(
              planId: d.planId,
              dayNumber: d.dayNumber,
              scheduledDate: d.scheduledDate.add(offset),
              chapters: d.chapters,
            ),
        ];

    PlanProgress calcWith(List<PlanDay> days, Set<ChapterRef> read) =>
        PlanProgressCalculator.calculate(
          plan: _plan,
          days: days,
          readChapters: read,
          today: DateTime(2024, 1, 2),
        );

    test('spring-forward drift (01:00) keeps today out of the past', () {
      // Day 1 done, day 2 (today) untouched → on track.
      final progress = calcWith(
        daysShiftedBy(const Duration(hours: 1)),
        _firstChapters(3),
      );
      expect(progress.expectedChaptersByToday, 6);
      expect(progress.approximateDaysDelta, 0);
      expect(progress.isOnTrack, isTrue);
    });

    test('fall-back drift (-01:00) does not push tomorrow into the past', () {
      final progress = calcWith(
        daysShiftedBy(const Duration(hours: -1)),
        _firstChapters(3),
      );
      expect(progress.expectedChaptersByToday, 6);
      expect(progress.approximateDaysDelta, 0);
      expect(progress.isOnTrack, isTrue);
    });
  });
}
