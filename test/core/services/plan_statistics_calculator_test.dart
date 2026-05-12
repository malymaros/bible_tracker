import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/services/plan_statistics_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

ReadingPlan _plan({
  List<String> selectedBookIds = const ['gen', 'matt'],
  int totalDays = 2,
}) {
  return ReadingPlan(
    id: 'plan-1',
    startDate: DateTime(2026, 5, 12),
    totalDays: totalDays,
    selectedBookIds: selectedBookIds,
    createdAt: DateTime(2026, 5, 1),
  );
}

PlanDay _day(int dayNumber, List<ChapterRef> chapters) {
  return PlanDay(
    planId: 'plan-1',
    dayNumber: dayNumber,
    scheduledDate: DateTime(2026, 5, 11 + dayNumber),
    chapters: chapters,
  );
}

void main() {
  test('statistics count only active plan chapters', () {
    final stats = PlanStatisticsCalculator.calculate(
      plan: _plan(),
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('gen', 2)]),
        _day(2, const [ChapterRef('matt', 1)]),
      ],
      readChapters: {const ChapterRef('gen', 1), const ChapterRef('matt', 1)},
    );

    expect(stats.totalPlanChapters, 3);
    expect(stats.completedPlanChapters, 2);
    expect(stats.remainingPlanChapters, 1);
    expect(stats.completionPercent, closeTo(66.666, 0.01));
  });

  test('read chapters outside the plan are ignored', () {
    final stats = PlanStatisticsCalculator.calculate(
      plan: _plan(selectedBookIds: const ['gen']),
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('gen', 2)]),
      ],
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('exod', 1),
        const ChapterRef('matt', 1),
      },
    );

    expect(stats.completedPlanChapters, 1);
    expect(stats.oldTestamentCompleted, 1);
    expect(stats.newTestamentCompleted, 0);
  });

  test('OT and NT progress is based only on selected plan books', () {
    final stats = PlanStatisticsCalculator.calculate(
      plan: _plan(),
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('gen', 2)]),
        _day(2, const [ChapterRef('matt', 1), ChapterRef('matt', 2)]),
      ],
      readChapters: {
        const ChapterRef('gen', 1),
        const ChapterRef('matt', 1),
        const ChapterRef('exod', 1),
      },
    );

    expect(stats.oldTestamentTotal, 2);
    expect(stats.oldTestamentCompleted, 1);
    expect(stats.newTestamentTotal, 2);
    expect(stats.newTestamentCompleted, 1);
  });

  test('completed books count is based only on selected plan books', () {
    final stats = PlanStatisticsCalculator.calculate(
      plan: _plan(selectedBookIds: const ['obad', 'phlm']),
      days: [
        _day(1, const [ChapterRef('obad', 1), ChapterRef('phlm', 1)]),
      ],
      readChapters: {const ChapterRef('obad', 1), const ChapterRef('gen', 1)},
    );

    expect(stats.completedBooksCount, 1);
    expect(stats.fullyCompletedSelectedBooks.single.id, 'obad');
    expect(stats.remainingBooksCount, 1);
  });

  test('not started books count is based only on selected plan books', () {
    final stats = PlanStatisticsCalculator.calculate(
      plan: _plan(selectedBookIds: const ['gen', 'matt']),
      days: [
        _day(1, const [ChapterRef('gen', 1), ChapterRef('matt', 1)]),
      ],
      readChapters: {const ChapterRef('gen', 1), const ChapterRef('exod', 1)},
    );

    expect(stats.notStartedSelectedBooks.map((book) => book.id), ['matt']);
  });

  test('deuterocanonical progress is present only for selected plan books', () {
    final withoutDeutero = PlanStatisticsCalculator.calculate(
      plan: _plan(selectedBookIds: const ['gen']),
      days: [
        _day(1, const [ChapterRef('gen', 1)]),
      ],
      readChapters: {const ChapterRef('gen', 1)},
    );
    final withDeutero = PlanStatisticsCalculator.calculate(
      plan: _plan(selectedBookIds: const ['tob']),
      days: [
        _day(1, const [ChapterRef('tob', 1), ChapterRef('tob', 2)]),
      ],
      readChapters: {const ChapterRef('tob', 1)},
    );

    expect(withoutDeutero.hasDeuterocanonicalBooks, isFalse);
    expect(withDeutero.hasDeuterocanonicalBooks, isTrue);
    expect(withDeutero.deuterocanonicalTotal, 2);
    expect(withDeutero.deuterocanonicalCompleted, 1);
  });
}
