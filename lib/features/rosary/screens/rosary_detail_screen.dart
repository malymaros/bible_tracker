import 'package:bible_tracker/core/models/rosary.dart';
import 'package:bible_tracker/core/services/rosary_service.dart';
import 'package:bible_tracker/features/rosary/screens/rosary_guide_screen.dart';
import 'package:bible_tracker/features/rosary/widgets/rosary_ui.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';

/// One rosary: its five mysteries and the order of prayers.
class RosaryDetailScreen extends StatefulWidget {
  final Rosary rosary;

  const RosaryDetailScreen({super.key, required this.rosary});

  @override
  State<RosaryDetailScreen> createState() => _RosaryDetailScreenState();
}

class _RosaryDetailScreenState extends State<RosaryDetailScreen> {
  late final List<RosaryOrderGroup> _groups = RosaryService.buildPrayerOrder(
    widget.rosary,
  );

  /// Id of the expanded prayer row; only one is open at a time.
  String? _openId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rosary = widget.rosary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: RosaryAppBarTitle(
          title: rosary.name,
          subtitle: rosary.daysLabel,
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        children: [
          _SectionLabel(l10n.rosaryMysteriesSection),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final m in rosary.mysteries)
                  _MysteryRow(mystery: m, divider: m.number > 1),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(l10n.rosaryPrayerOrderSection),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var gi = 0; gi < _groups.length; gi++) ...[
                  if (gi > 0)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Divider(height: 1, color: AppColors.surfaceMuted),
                    ),
                  _GroupHeader(group: _groups[gi]),
                  for (final item in _groups[gi].items)
                    _OrderRow(
                      item: item,
                      open: item.id == _openId,
                      onTap: () => setState(
                        () => _openId = _openId == item.id ? null : item.id,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    key: const Key('rosary-guide-button'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RosaryGuideScreen(rosary: rosary),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.rosaryGuideButton),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rosaryGuideCaption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.9,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _MysteryRow extends StatelessWidget {
  final RosaryMystery mystery;
  final bool divider;

  const _MysteryRow({required this.mystery, required this.divider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: divider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceMuted)),
            )
          : null,
      child: Row(
        children: [
          RosaryNumberBadge(number: mystery.number),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mystery.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '…${mystery.insert}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ScriptureRefLink(scriptureRef: mystery.ref),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final RosaryOrderGroup group;

  const _GroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Row(
        children: [
          Text(
            group.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.goldDark,
            ),
          ),
          if (group.badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.goldDark,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                group.badge!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final RosaryOrderItem item;
  final bool open;
  final VoidCallback onTap;

  const _OrderRow({
    required this.item,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: open ? RosaryColors.highlight : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: open,
            child: InkWell(
              key: Key('rosary-order-${item.id}'),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _marker(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: item.strong || open
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: open ? AppColors.goldDark : AppColors.text,
                            ),
                          ),
                          if (item.sub != null)
                            Text(
                              item.sub!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more,
                        size: 20,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PrayerTextView(text: item.text),
                  if (item.note != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.note!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _marker() {
    if (item.count != null) {
      return Container(
        constraints: const BoxConstraints(minWidth: 34),
        height: 22,
        margin: const EdgeInsets.only(top: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          item.count!,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.goldDark,
          ),
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.strong ? AppColors.gold : null,
        border: Border.all(color: AppColors.gold, width: 2),
      ),
    );
  }
}
