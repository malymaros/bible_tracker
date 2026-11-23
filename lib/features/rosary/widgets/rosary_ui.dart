import 'package:bible_tracker/core/models/reader_context.dart';
import 'package:bible_tracker/core/models/rosary.dart';
import 'package:bible_tracker/core/services/rosary_service.dart';
import 'package:bible_tracker/features/bible/screens/reader_screen.dart';
import 'package:bible_tracker/features/rosary/screens/rosary_list_screen.dart';
import 'package:bible_tracker/l10n/app_localizations.dart';
import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';

/// Extra colors of the rosary screens on top of [AppColors].
abstract final class RosaryColors {
  static const highlight = Color(0xFFFBF4E4);
  static const highlightBorder = Color(0xFFEBD7AA);
  static const textStrong = Color(0xFF1A110A);
}

/// Custom rosary-beads icon (a ring of beads with a small cross).
class RosaryBeadsIcon extends StatelessWidget {
  final double size;
  final Color color;

  const RosaryBeadsIcon({
    super.key,
    this.size = 24,
    this.color = AppColors.goldDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RosaryBeadsPainter(color),
    );
  }
}

class _RosaryBeadsPainter extends CustomPainter {
  final Color color;

  const _RosaryBeadsPainter(this.color);

  static const _beads = [
    Offset(12, 3.2),
    Offset(16.6, 4.7),
    Offset(19.2, 8.6),
    Offset(18.6, 13.2),
    Offset(7.4, 4.7),
    Offset(4.8, 8.6),
    Offset(5.4, 13.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final c in _beads) {
      canvas.drawCircle(c, 1.3, paint);
    }
    final path = Path()
      ..moveTo(6.6, 14.4)
      ..lineTo(12, 16.6)
      ..lineTo(17.4, 14.4)
      ..moveTo(12, 16.6)
      ..lineTo(12, 22.6)
      ..moveTo(9.6, 19)
      ..lineTo(14.4, 19);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RosaryBeadsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Opens the rosary list; overlays the title of the plan's today's
/// reading card. Compact (36 px) to fit beside the title.
class RosaryNavButton extends StatelessWidget {
  const RosaryNavButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const Key('plan-rosary-nav-button'),
      tooltip: l10n.rosaryTitle,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const RosaryListScreen())),
      icon: const RosaryBeadsIcon(),
    );
  }
}

/// Tappable Bible reference ("Lk 1,26-38") that opens the reader.
class ScriptureRefLink extends StatelessWidget {
  final ScriptureRef scriptureRef;

  const ScriptureRefLink({super.key, required this.scriptureRef});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.goldDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(48, 40),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      // The reader cannot scroll to a verse yet; it opens the chapter.
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReaderScreen(
            bookId: scriptureRef.bookId,
            chapterNumber: scriptureRef.chapter,
            initialVerse: scriptureRef.verseStart,
            readerContext: ReaderContext.books,
          ),
        ),
      ),
      child: Text(RosaryService.formatRef(scriptureRef)),
    );
  }
}

/// Prayer text with its insert highlighted.
class PrayerTextView extends StatelessWidget {
  final PrayerText text;
  final double fontSize;
  final double height;

  const PrayerTextView({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.height = 1.65,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          height: height,
          color: AppColors.text,
        ),
        children: [
          TextSpan(text: text.before),
          if (text.hasInsert)
            TextSpan(
              text: text.insert,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.goldDark,
              ),
            ),
          if (text.after.isNotEmpty) TextSpan(text: text.after),
        ],
      ),
    );
  }
}

/// Small circular number badge (mystery number).
class RosaryNumberBadge extends StatelessWidget {
  final int number;
  final double size;
  final Color background;

  const RosaryNumberBadge({
    super.key,
    required this.number,
    this.size = 28,
    this.background = AppColors.goldSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.goldDark,
        ),
      ),
    );
  }
}

/// Two-line centered app-bar title (name + subtitle).
class RosaryAppBarTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const RosaryAppBarTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// One mystery as the detail list shows it: number, name, the "…insert"
/// added to each Hail Mary, and the tappable scripture reference. The guide
/// shows the same row so the mystery stays in view while praying.
class RosaryMysteryRow extends StatelessWidget {
  final RosaryMystery mystery;
  final Color badgeBackground;

  const RosaryMysteryRow({
    super.key,
    required this.mystery,
    this.badgeBackground = AppColors.goldSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RosaryNumberBadge(number: mystery.number, background: badgeBackground),
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
    );
  }
}
