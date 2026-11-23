import 'package:bible_tracker/core/constants/rosary.dart';
import 'package:bible_tracker/core/models/rosary.dart';
import 'package:bible_tracker/core/services/rosary_service.dart';
import 'package:bible_tracker/features/rosary/screens/rosary_detail_screen.dart';
import 'package:bible_tracker/features/rosary/widgets/rosary_ui.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/providers/plan_providers.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// List of the four rosaries with a weekday picker.
class RosaryListScreen extends ConsumerStatefulWidget {
  const RosaryListScreen({super.key});

  @override
  ConsumerState<RosaryListScreen> createState() => _RosaryListScreenState();
}

class _RosaryListScreenState extends ConsumerState<RosaryListScreen> {
  /// Selected `DateTime.weekday`; `null` until the user picks a day.
  int? _selectedWeekday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayWeekday = ref.watch(todayProvider).weekday;
    final selectedWeekday = _selectedWeekday ?? todayWeekday;
    final todayRosary = RosaryService.forWeekday(todayWeekday);
    final selectedRosary = RosaryService.forWeekday(selectedWeekday);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.rosaryTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            _WeekdayStrip(
              todayWeekday: todayWeekday,
              selectedWeekday: selectedWeekday,
              onSelected: (w) => setState(() => _selectedWeekday = w),
            ),
            const SizedBox(height: 14),
            for (final rosary in kRosaries) ...[
              _RosaryCard(
                rosary: rosary,
                isToday: rosary.kind == todayRosary.kind,
                isSelected: rosary.kind == selectedRosary.kind,
                todayLabel: l10n.rosaryTodayBadge,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekdayStrip extends StatelessWidget {
  final int todayWeekday;
  final int selectedWeekday;
  final ValueChanged<int> onSelected;

  const _WeekdayStrip({
    required this.todayWeekday,
    required this.selectedWeekday,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _dayButton(i + 1)),
          ],
        ],
      ),
    );
  }

  Widget _dayButton(int weekday) {
    final selected = weekday == selectedWeekday;
    final isToday = weekday == todayWeekday;
    final color = selected || isToday
        ? AppColors.goldDark
        : AppColors.textMuted;
    final fullName = kWeekdayNames[weekday - 1];
    return Semantics(
      button: true,
      selected: selected,
      label: isToday ? '$fullName (dnes)' : fullName,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        elevation: selected ? 1 : 0,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('rosary-day-$weekday'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelected(weekday),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                kWeekdayShortLabels[weekday - 1],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  decoration: isToday && !selected
                      ? TextDecoration.underline
                      : null,
                  decorationColor: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RosaryCard extends StatelessWidget {
  final Rosary rosary;
  final bool isToday;
  final bool isSelected;
  final String todayLabel;

  const _RosaryCard({
    required this.rosary,
    required this.isToday,
    required this.isSelected,
    required this.todayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: isSelected ? RosaryColors.highlight : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isSelected
            ? const BorderSide(color: AppColors.gold, width: 2)
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: Key('rosary-card-${rosary.kind.name}'),
        borderRadius: radius,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RosaryDetailScreen(rosary: rosary),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSelected ? 15 : 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          rosary.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: RosaryColors.textStrong,
                          ),
                        ),
                        if (isToday) _TodayBadge(label: todayLabel),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rosary.daysLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.goldDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      RosaryService.mysteryShortList(rosary),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                size: 22,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  final String label;

  const _TodayBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}
