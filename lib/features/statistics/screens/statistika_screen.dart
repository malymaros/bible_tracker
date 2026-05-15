import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_progress.dart';
import 'package:bible_tracker/core/models/plan_statistics.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/services/plan_progress_calculator.dart';
import 'package:bible_tracker/core/services/plan_statistics_calculator.dart';
import 'package:bible_tracker/core/utils/chapter_count_format.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _formatDelta(int delta) {
  final abs = delta.abs();
  final sign = delta > 0 ? '+' : '';
  if (abs == 1) return '$sign$delta kapitola';
  if (abs <= 4) return '$sign$delta kapitoly';
  return '$sign$delta kapitol';
}

class StatistikaScreen extends ConsumerWidget {
  const StatistikaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activePlan = ref.watch(activePlanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.screenStatistika)),
      body: activePlan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (plan) {
          if (plan == null) {
            return EmptyState(
              icon: Icons.insights_outlined,
              title: l10n.statsNoPlan,
            );
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
        _OldTestamentStats(stats: stats),
        const SizedBox(height: 12),
        _NewTestamentStats(stats: stats),
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

    final booksTotal = stats.totalBooksCount;
    final booksCompleted = stats.completedBooksCount;
    final booksPercent =
        booksTotal == 0 ? 0.0 : booksCompleted / booksTotal * 100;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.statsPlanProgressTitle),
          _MetricLine(
            label: l10n.planCompletedChapters,
            value:
                '${stats.completedPlanChapters}/${stats.totalPlanChapters}',
            valueKey: 'stats-completed-plan-chapters',
          ),
          GoldProgressBar(
            value: stats.totalPlanChapters == 0
                ? 0
                : stats.completedPlanChapters / stats.totalPlanChapters,
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: '${stats.completionPercent.toStringAsFixed(1)} %',
            valueKey: 'stats-plan-percent',
          ),
          const SizedBox(height: 8),
          _MetricLine(
            label: l10n.statsCompletedBooksInPlan,
            value: '$booksCompleted/$booksTotal',
            valueKey: 'stats-completed-books-overall',
          ),
          GoldProgressBar(
            value: booksTotal == 0 ? 0 : booksCompleted / booksTotal,
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: '${booksPercent.toStringAsFixed(1)} %',
            valueKey: 'stats-books-percent',
          ),
          const SizedBox(height: 8),
          _MetricLine(
            label: l10n.statsPlanStatus,
            value: status,
            valueKey: 'stats-plan-status',
          ),
          _MetricLine(
            label: l10n.planExpectedByToday,
            value: formatChapterCount(progress.expectedChaptersByToday),
            valueKey: 'stats-expected-by-today',
          ),
          _MetricLine(
            label: l10n.planAheadBehind,
            value: _formatDelta(progress.aheadBehindChapterCount),
            valueKey: 'stats-ahead-behind',
          ),
        ],
      ),
    );
  }
}

class _OldTestamentStats extends StatelessWidget {
  final PlanStatistics stats;

  const _OldTestamentStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chaptersTotal = stats.oldTestamentTotal;
    final chaptersCompleted = stats.oldTestamentCompleted;
    final chaptersPercent = chaptersTotal == 0
        ? 0.0
        : chaptersCompleted / chaptersTotal * 100;

    final booksTotal = stats.otTotalBooksCount;
    final booksCompleted = stats.otCompletedBooksCount;
    final booksPercent =
        booksTotal == 0 ? 0.0 : booksCompleted / booksTotal * 100;

    return AppCard(
      key: const Key('stats-ot-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Starý zákon'),
          _MetricLine(
            label: l10n.planCompletedChapters,
            value: '$chaptersCompleted/$chaptersTotal',
            valueKey: 'stats-old-testament',
          ),
          GoldProgressBar(
            value: chaptersTotal == 0 ? 0 : chaptersCompleted / chaptersTotal,
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: '${chaptersPercent.toStringAsFixed(1)} %',
            valueKey: 'stats-ot-percent',
          ),
          const SizedBox(height: 8),
          _MetricLine(
            label: l10n.statsCompletedBooksInPlan,
            value: '$booksCompleted/$booksTotal',
            valueKey: 'stats-ot-books',
          ),
          GoldProgressBar(
            value: booksTotal == 0 ? 0 : booksCompleted / booksTotal,
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: '${booksPercent.toStringAsFixed(1)} %',
            valueKey: 'stats-ot-books-percent',
          ),
        ],
      ),
    );
  }
}

class _NewTestamentStats extends StatelessWidget {
  final PlanStatistics stats;

  const _NewTestamentStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chaptersTotal = stats.newTestamentTotal;
    final chaptersCompleted = stats.newTestamentCompleted;
    final chaptersPercent = chaptersTotal == 0
        ? 0.0
        : chaptersCompleted / chaptersTotal * 100;

    final booksTotal = stats.ntTotalBooksCount;
    final booksCompleted = stats.ntCompletedBooksCount;
    final booksPercent =
        booksTotal == 0 ? 0.0 : booksCompleted / booksTotal * 100;

    return AppCard(
      key: const Key('stats-nt-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Nový zákon'),
          _MetricLine(
            label: l10n.planCompletedChapters,
            value: '$chaptersCompleted/$chaptersTotal',
            valueKey: 'stats-new-testament',
          ),
          GoldProgressBar(
            value: chaptersTotal == 0 ? 0 : chaptersCompleted / chaptersTotal,
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: '${chaptersPercent.toStringAsFixed(1)} %',
            valueKey: 'stats-nt-percent',
          ),
          const SizedBox(height: 8),
          _MetricLine(
            label: l10n.statsCompletedBooksInPlan,
            value: '$booksCompleted/$booksTotal',
            valueKey: 'stats-nt-books',
          ),
          GoldProgressBar(
            value: booksTotal == 0 ? 0 : booksCompleted / booksTotal,
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: '${booksPercent.toStringAsFixed(1)} %',
            valueKey: 'stats-nt-books-percent',
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.text),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              key: Key(valueKey ?? 'stats-$label'),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
