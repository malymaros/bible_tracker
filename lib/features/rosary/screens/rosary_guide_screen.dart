import 'package:bible_tracker/core/models/rosary.dart';
import 'package:bible_tracker/core/services/rosary_service.dart';
import 'package:bible_tracker/features/rosary/widgets/rosary_ui.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';

/// Step-by-step guide through the whole rosary. Progress is not persisted.
class RosaryGuideScreen extends StatefulWidget {
  final Rosary rosary;

  const RosaryGuideScreen({super.key, required this.rosary});

  @override
  State<RosaryGuideScreen> createState() => _RosaryGuideScreenState();
}

class _RosaryGuideScreenState extends State<RosaryGuideScreen> {
  late final List<RosaryStep> _steps = RosaryService.buildSteps(widget.rosary);
  int _index = 0;

  bool get _isLast => _index == _steps.length - 1;

  void _next() => setState(() => _index = _isLast ? 0 : _index + 1);

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = _steps[_index];
    final mystery = step.decade > 0
        ? widget.rosary.mysteries[step.decade - 1]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.readerClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: RosaryAppBarTitle(
          title: widget.rosary.name,
          subtitle: step.stageLabel,
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GoldProgressBar(
                key: const Key('rosary-guide-progress'),
                value: (_index + 1) / _steps.length,
                height: 4,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (mystery != null) ...[
                      _MysteryChip(mystery: mystery),
                      const SizedBox(height: 16),
                    ],
                    _BeadRow(step: step),
                    const SizedBox(height: 16),
                    Expanded(child: _StepCard(step: step)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 56,
                    child: OutlinedButton(
                      key: const Key('rosary-guide-back'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.surface,
                        // Clearly drawn even when disabled on the first step,
                        // so the user sees there is a way back.
                        side: const BorderSide(
                          color: AppColors.gold,
                          width: 1.5,
                        ),
                        disabledForegroundColor: AppColors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _index > 0 ? _back : null,
                      child: Icon(
                        Icons.chevron_left,
                        semanticLabel: l10n.rosaryGuideBack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        key: const Key('rosary-guide-next'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _next,
                        child: Text(
                          _isLast
                              ? l10n.rosaryGuideRestart
                              : l10n.rosaryGuideNext,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MysteryChip extends StatelessWidget {
  final RosaryMystery mystery;

  const _MysteryChip({required this.mystery});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('rosary-guide-mystery'),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: RosaryColors.highlight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RosaryColors.highlightBorder),
      ),
      child: RosaryMysteryRow(
        mystery: mystery,
        badgeBackground: AppColors.surface,
      ),
    );
  }
}

class _BeadRow extends StatelessWidget {
  final RosaryStep step;

  const _BeadRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var k = 1; k <= step.beadCount; k++) ...[
            if (k > 1) const SizedBox(width: 9),
            _bead(current: k == step.bead, done: k < step.bead),
          ],
        ],
      ),
    );
  }

  Widget _bead({required bool current, required bool done}) {
    final size = current ? 18.0 : 12.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: current
            ? AppColors.gold
            : done
            ? AppColors.goldDark
            : AppColors.surface,
        border: current || done
            ? null
            : Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: current
            ? const [BoxShadow(color: AppColors.goldSoft, spreadRadius: 4)]
            : null,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final RosaryStep step;

  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title.toUpperCase(),
                key: const Key('rosary-guide-step-title'),
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 12),
              PrayerTextView(text: step.text, fontSize: 19, height: 1.7),
            ],
          ),
        ),
      ),
    );
  }
}
