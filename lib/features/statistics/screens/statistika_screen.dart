import 'package:bible_tracker/core/constants/bible_books.dart';
import 'package:bible_tracker/core/models/bible_book.dart';
import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_progress.dart';
import 'package:bible_tracker/core/models/plan_statistics.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/services/plan_progress_calculator.dart';
import 'package:bible_tracker/core/services/plan_statistics_calculator.dart';
import 'package:bible_tracker/features/plan/screens/plan_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatistikaScreen extends ConsumerWidget {
  const StatistikaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activePlan = ref.watch(activePlanProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenStatistika)),
      body: activePlan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (plan) {
          if (plan == null) {
            return Center(child: Text(l10n.statsNoPlan));
          }
          return _PlanStatisticsBody(plan: plan);
        },
      ),
    );
  }
}

class _PlanStatisticsBody extends ConsumerWidget {
  final ReadingPlan plan;

  const _PlanStatisticsBody({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days =
        ref.watch(planDaysProvider(plan.id)).value ?? const <PlanDay>[];
    final readChapters =
        ref.watch(readChaptersProvider).value ?? const <ChapterRef>{};
    final today = ref.watch(todayProvider);
    final stats = PlanStatisticsCalculator.calculate(
      plan: plan,
      days: days,
      readChapters: readChapters,
    );
    final progress = PlanProgressCalculator.calculate(
      plan: plan,
      days: days,
      readChapters: readChapters,
      today: today,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _ProgressSummary(stats: stats, progress: progress),
        const SizedBox(height: 12),
        _TestamentStats(stats: stats),
        if (stats.hasDeuterocanonicalBooks) ...[
          const SizedBox(height: 12),
          _DeuterocanonicalStats(stats: stats),
        ],
        const SizedBox(height: 12),
        _BookStats(stats: stats),
        const SizedBox(height: 12),
        _TodaySummary(days: days, today: today),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final PlanStatistics stats;
  final PlanProgress progress;

  const _ProgressSummary({required this.stats, required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = progress.isAhead
        ? l10n.planAhead
        : progress.isBehind
        ? l10n.planBehind
        : l10n.planOnTrack;

    return _StatsSection(
      title: l10n.statsPlanProgressTitle,
      children: [
        _MetricLine(
          label: l10n.planCompletedChapters,
          value: '${stats.completedPlanChapters}/${stats.totalPlanChapters}',
          valueKey: 'stats-completed-plan-chapters',
        ),
        _MetricLine(
          label: l10n.statsRemainingPlanChapters,
          value: '${stats.remainingPlanChapters}',
          valueKey: 'stats-remaining-plan-chapters',
        ),
        _MetricLine(
          label: l10n.planCompletionPercent,
          value: '${stats.completionPercent.toStringAsFixed(1)} %',
          valueKey: 'stats-plan-percent',
        ),
        _MetricLine(
          label: l10n.statsPlanStatus,
          value: status,
          valueKey: 'stats-plan-status',
        ),
        _MetricLine(
          label: l10n.planExpectedByToday,
          value: '${progress.expectedChaptersByToday}',
          valueKey: 'stats-expected-by-today',
        ),
        _MetricLine(
          label: l10n.planAheadBehind,
          value: '${progress.aheadBehindChapterCount}',
          valueKey: 'stats-ahead-behind',
        ),
      ],
    );
  }
}

class _TestamentStats extends StatelessWidget {
  final PlanStatistics stats;

  const _TestamentStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StatsSection(
      title: l10n.statsTestamentsTitle,
      children: [
        _MetricLine(
          label: l10n.statsOldTestamentInPlan,
          value: '${stats.oldTestamentCompleted}/${stats.oldTestamentTotal}',
          valueKey: 'stats-old-testament',
        ),
        _MetricLine(
          label: l10n.statsNewTestamentInPlan,
          value: '${stats.newTestamentCompleted}/${stats.newTestamentTotal}',
          valueKey: 'stats-new-testament',
        ),
      ],
    );
  }
}

class _DeuterocanonicalStats extends StatelessWidget {
  final PlanStatistics stats;

  const _DeuterocanonicalStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StatsSection(
      key: const Key('stats-deuterocanonical-section'),
      title: l10n.statsDeuterocanonicalInPlan,
      children: [
        _MetricLine(
          label: l10n.statsDeuterocanonicalInPlan,
          value:
              '${stats.deuterocanonicalCompleted}/${stats.deuterocanonicalTotal}',
          valueKey: 'stats-deuterocanonical',
        ),
      ],
    );
  }
}

class _BookStats extends StatelessWidget {
  final PlanStatistics stats;

  const _BookStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StatsSection(
      title: l10n.statsBooksTitle,
      children: [
        _MetricLine(
          label: l10n.statsCompletedBooksInPlan,
          value: '${stats.completedBooksCount}',
          valueKey: 'stats-completed-books-count',
        ),
        _MetricLine(
          label: l10n.statsRemainingBooksInPlan,
          value: '${stats.remainingBooksCount}',
          valueKey: 'stats-remaining-books-count',
        ),
        _MetricLine(
          label: l10n.statsFullyCompletedSelectedBooks,
          value: _bookNames(stats.fullyCompletedSelectedBooks),
          valueKey: 'stats-fully-completed-books',
        ),
        _MetricLine(
          label: l10n.statsNotStartedSelectedBooks,
          value: _bookNames(stats.notStartedSelectedBooks),
          valueKey: 'stats-not-started-books',
        ),
      ],
    );
  }

  String _bookNames(List<BibleBook> books) {
    if (books.isEmpty) return '-';
    return books.map((book) => book.shortName).join(', ');
  }
}

class _TodaySummary extends StatelessWidget {
  final List<PlanDay> days;
  final DateTime today;

  const _TodaySummary({required this.days, required this.today});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayDays = days.where((day) => _sameDate(day.scheduledDate, today));
    final chapters = [
      for (final day in todayDays)
        for (final chapter in day.chapters) _chapterLabel(chapter),
    ];

    return _StatsSection(
      title: l10n.statsTodaySummary,
      children: [
        Text(chapters.isEmpty ? l10n.planNoReadingToday : chapters.join(', ')),
      ],
    );
  }

  String _chapterLabel(ChapterRef chapter) {
    final book = kBibleBooks.firstWhere((book) => book.id == chapter.bookId);
    return '${book.shortName} ${chapter.chapterNumber}';
  }
}

class _StatsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StatsSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;
  final String? valueKey;

  const _MetricLine({required this.label, required this.value, this.valueKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              key: Key(valueKey ?? 'stats-$label'),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
