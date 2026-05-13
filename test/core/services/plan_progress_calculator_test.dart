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

    test('isOnTrack is true', () => expect(progress.isOnTrack, isTrue));
    test('isAhead is false', () => expect(progress.isAhead, isFalse));
    test('isBehind is false', () => expect(progress.isBehind, isFalse));
  });

  // ── On start date ───────────────────────────────────────────────────────

  group('on plan start date (Jan 1, nothing read)', () {
    late final progress = _calc(today: DateTime(2024, 1, 1));

    test('expectedChaptersByToday is 3 (day 1 chapters)', () {
      expect(progress.expectedChaptersByToday, 3);
    });

    test('completedPlanChapters is 0', () {
      expect(progress.completedPlanChapters, 0);
    });

    test('aheadBehindChapterCount is -3', () {
      expect(progress.aheadBehindChapterCount, -3);
    });

    test('isBehind is true', () => expect(progress.isBehind, isTrue));
  });

  group('on plan start date (Jan 1), day 1 fully read', () {
    late final progress = _calc(
      today: DateTime(2024, 1, 1),
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('gen', 2),
        const ChapterRef('gen', 3),
      },
    );

    test('completedPlanChapters is 3', () {
      expect(progress.completedPlanChapters, 3);
    });

    test('aheadBehindChapterCount is 0', () {
      expect(progress.aheadBehindChapterCount, 0);
    });

    test('isOnTrack is true', () => expect(progress.isOnTrack, isTrue));
  });

  // ── Mid-plan ────────────────────────────────────────────────────────────

  group('mid-plan (Jan 2): only day 1 read', () {
    late final progress = _calc(
      today: DateTime(2024, 1, 2),
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('gen', 2),
        const ChapterRef('gen', 3),
      },
    );

    test('expectedChaptersByToday is 6 (days 1+2)', () {
      expect(progress.expectedChaptersByToday, 6);
    });

    test('completedPlanChapters is 3', () {
      expect(progress.completedPlanChapters, 3);
    });

    test('aheadBehindChapterCount is -3', () {
      expect(progress.aheadBehindChapterCount, -3);
    });

    test('isBehind is true', () => expect(progress.isBehind, isTrue));
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
      expect(progress.aheadBehindChapterCount, 0);
      expect(progress.isOnTrack, isTrue);
    });

    test('having read nothing after end → behind by 9', () {
      final progress = _calc(today: DateTime(2024, 1, 5));
      expect(progress.aheadBehindChapterCount, -9);
      expect(progress.isBehind, isTrue);
    });
  });

  // ── Ahead / behind / on-track ────────────────────────────────────────────

  group('ahead state', () {
    // Jan 1: expected 3, read 5 plan chapters → ahead by 2.
    late final progress = _calc(
      today: DateTime(2024, 1, 1),
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('gen', 2),
        const ChapterRef('gen', 3),
        const ChapterRef('gen', 4),
        const ChapterRef('gen', 5),
      },
    );

    test('completedPlanChapters is 5', () => expect(progress.completedPlanChapters, 5));
    test('expectedChaptersByToday is 3', () => expect(progress.expectedChaptersByToday, 3));
    test('aheadBehindChapterCount is +2', () => expect(progress.aheadBehindChapterCount, 2));
    test('isAhead is true', () => expect(progress.isAhead, isTrue));
    test('isBehind is false', () => expect(progress.isBehind, isFalse));
    test('isOnTrack is false', () => expect(progress.isOnTrack, isFalse));
  });

  group('behind state', () {
    // Jan 2: expected 6, read only 2 → behind by 4.
    late final progress = _calc(
      today: DateTime(2024, 1, 2),
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('gen', 2),
      },
    );

    test('aheadBehindChapterCount is -4', () => expect(progress.aheadBehindChapterCount, -4));
    test('isBehind is true', () => expect(progress.isBehind, isTrue));
    test('isAhead is false', () => expect(progress.isAhead, isFalse));
    test('isOnTrack is false', () => expect(progress.isOnTrack, isFalse));
  });

  group('on-track state', () {
    // Jan 2: expected 6, read exactly 6 → on track.
    late final progress = _calc(
      today: DateTime(2024, 1, 2),
      readChapters: {
        for (var i = 1; i <= 6; i++) ChapterRef('gen', i),
      },
    );

    test('aheadBehindChapterCount is 0', () => expect(progress.aheadBehindChapterCount, 0));
    test('isOnTrack is true', () => expect(progress.isOnTrack, isTrue));
    test('isAhead is false', () => expect(progress.isAhead, isFalse));
    test('isBehind is false', () => expect(progress.isBehind, isFalse));
  });

  // ── Chapters outside the plan ───────────────────────────────────────────

  group('chapters read outside the plan do not count', () {
    // The plan covers Gen 1–9.
    // Reading Gen 10–15 (not in the plan) and Matt 1 (different book entirely)
    // must not contribute to completedPlanChapters.
    late final progress = _calc(
      today: DateTime(2024, 1, 1),
      readChapters: {
        const ChapterRef('gen', 10), // outside plan
        const ChapterRef('gen', 11), // outside plan
        const ChapterRef('matt', 1), // outside plan
      },
    );

    test('completedPlanChapters is 0', () {
      expect(progress.completedPlanChapters, 0);
    });

    test('aheadBehindChapterCount is -3 (behind, not ahead)', () {
      expect(progress.aheadBehindChapterCount, -3);
    });

    test('isBehind is true', () => expect(progress.isBehind, isTrue));
  });

  // ── Mixed: plan chapters + outside chapters ──────────────────────────────

  group('mix of plan and non-plan chapters read', () {
    // Read Gen 1 (in plan) + Gen 50 (not in plan).
    // On Jan 1 (expected 3). Completed = 1. Delta = -2.
    late final progress = _calc(
      today: DateTime(2024, 1, 1),
      readChapters: {
        const ChapterRef('gen', 1), // in plan
        const ChapterRef('gen', 50), // NOT in plan
      },
    );

    test('completedPlanChapters counts only plan chapters', () {
      expect(progress.completedPlanChapters, 1);
    });

    test('aheadBehindChapterCount is -2', () {
      expect(progress.aheadBehindChapterCount, -2);
    });
  });

  // ── approximateDaysDelta ────────────────────────────────────────────────

  group('approximateDaysDelta', () {
    // Plan: 3 days, 9 chapters → average 3 chapters/day.

    test('zero when on track', () {
      // Jan 1: expected 3, read 3 → delta = 0.
      final p = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: {
          const ChapterRef('gen', 1),
          const ChapterRef('gen', 2),
          const ChapterRef('gen', 3),
        },
      );
      expect(p.approximateDaysDelta, 0);
    });

    test('positive when ahead by whole days', () {
      // Jan 1: expected 3, read 6 → chapterDelta = +3 → 3*3/9 = 1 day.
      final p = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: {for (var i = 1; i <= 6; i++) ChapterRef('gen', i)},
      );
      expect(p.approximateDaysDelta, 1);
    });

    test('negative when behind by whole days', () {
      // Jan 2: expected 6, read 3 → chapterDelta = -3 → -3*3/9 = -1 day.
      final p = _calc(
        today: DateTime(2024, 1, 2),
        readChapters: {
          const ChapterRef('gen', 1),
          const ChapterRef('gen', 2),
          const ChapterRef('gen', 3),
        },
      );
      expect(p.approximateDaysDelta, -1);
    });

    test('minimum 1 for small non-zero ahead delta', () {
      // Jan 1: expected 3, read 4 → chapterDelta = +1 → 1*3/9 ≈ 0.33 → clamp to 1.
      final p = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: {
          const ChapterRef('gen', 1),
          const ChapterRef('gen', 2),
          const ChapterRef('gen', 3),
          const ChapterRef('gen', 4),
        },
      );
      expect(p.approximateDaysDelta, 1);
    });

    test('minimum -1 for small non-zero behind delta', () {
      // Jan 1: expected 3, read 2 → chapterDelta = -1 → -1*3/9 ≈ -0.33 → clamp to -1.
      final p = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: {
          const ChapterRef('gen', 1),
          const ChapterRef('gen', 2),
        },
      );
      expect(p.approximateDaysDelta, -1);
    });

    test('value is based on totalPlanChapters / totalPlanDays ratio', () {
      // Jan 1: expected 3, read 9 → chapterDelta = +6 → 6*3/9 = 2 days.
      final p = _calc(
        today: DateTime(2024, 1, 1),
        readChapters: _allPlanChapters,
      );
      expect(p.approximateDaysDelta, 2);
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
      // 3 of 9 chapters read = 33.33...%
      final progress = _calc(
        today: DateTime(2024, 1, 2),
        readChapters: {
          const ChapterRef('gen', 1),
          const ChapterRef('gen', 2),
          const ChapterRef('gen', 3),
        },
      );
      expect(progress.completionPercent, closeTo(3 / 9 * 100, 0.001));
    });
  });

  // ── today time component stripped ────────────────────────────────────────

  group('today time component is stripped', () {
    test('Jan 1 at 23:59:59 is treated as Jan 1', () {
      final progress = _calc(today: DateTime(2024, 1, 1, 23, 59, 59));
      expect(progress.expectedChaptersByToday, 3); // day 1 included
    });

    test('Jan 1 at 00:00:01 is treated as Jan 1', () {
      final progress = _calc(today: DateTime(2024, 1, 1, 0, 0, 1));
      expect(progress.expectedChaptersByToday, 3);
    });
  });
}
