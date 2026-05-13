import 'package:bible_tracker/core/models/chapter_ref.dart';
import 'package:bible_tracker/core/models/plan_day.dart';
import 'package:bible_tracker/core/models/plan_progress.dart';
import 'package:bible_tracker/core/models/plan_statistics.dart';
import 'package:bible_tracker/core/models/reading_plan.dart';
import 'package:bible_tracker/core/services/plan_progress_calculator.dart';
import 'package:bible_tracker/core/services/plan_statistics_calculator.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.statsPlanProgressTitle),
          GoldProgressBar(
            value: stats.totalPlanChapters == 0
                ? 0
                : stats.completedPlanChapters / stats.totalPlanChapters,
          ),
          const SizedBox(height: 12),
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
            label: l10n.statsCompletedBooksInPlan,
            value: '${stats.completedBooksCount}/${stats.totalBooksCount}',
            valueKey: 'stats-completed-books-overall',
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
    final total = stats.oldTestamentTotal;
    final completed = stats.oldTestamentCompleted;
    return AppCard(
      key: const Key('stats-ot-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Starý zákon'),
          _MetricLine(
            label: l10n.planCompletedChapters,
            value: '$completed/$total',
            valueKey: 'stats-old-testament',
          ),
          GoldProgressBar(
            value: total == 0 ? 0 : completed / total,
          ),
          const SizedBox(height: 12),
          _MetricLine(
            label: l10n.statsCompletedBooksInPlan,
            value: '${stats.otCompletedBooksCount}/${stats.otTotalBooksCount}',
            valueKey: 'stats-ot-books',
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: total == 0
                ? '0.0 %'
                : '${(completed / total * 100).toStringAsFixed(1)} %',
            valueKey: 'stats-ot-percent',
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
    final total = stats.newTestamentTotal;
    final completed = stats.newTestamentCompleted;
    return AppCard(
      key: const Key('stats-nt-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Nový zákon'),
          _MetricLine(
            label: l10n.planCompletedChapters,
            value: '$completed/$total',
            valueKey: 'stats-new-testament',
          ),
          GoldProgressBar(
            value: total == 0 ? 0 : completed / total,
          ),
          const SizedBox(height: 12),
          _MetricLine(
            label: l10n.statsCompletedBooksInPlan,
            value: '${stats.ntCompletedBooksCount}/${stats.ntTotalBooksCount}',
            valueKey: 'stats-nt-books',
          ),
          _MetricLine(
            label: l10n.planCompletionPercent,
            value: total == 0
                ? '0.0 %'
                : '${(completed / total * 100).toStringAsFixed(1)} %',
            valueKey: 'stats-nt-percent',
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

