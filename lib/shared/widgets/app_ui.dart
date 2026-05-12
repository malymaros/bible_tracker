import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFFFFCF7);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF3EEE6);
  static const border = Color(0xFFF0E3CC);
  static const gold = Color(0xFFD6A645);
  static const goldDark = Color(0xFF9B6A10);
  static const goldSoft = Color(0xFFF7E8C3);
  static const text = Color(0xFF2B2418);
  static const textMuted = Color(0xFF5A5047);
  static const error = Color(0xFFB3261E);
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class GoldProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const GoldProgressBar({super.key, required this.value, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.goldSoft,
        valueColor: const AlwaysStoppedAnimation(AppColors.gold),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: AppColors.gold),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const StatusBadge({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.goldDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return FilledButton(onPressed: onPressed, child: label);
    }
    return FilledButton.icon(onPressed: onPressed, icon: icon!, label: label);
  }
}

class AppOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;

  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return OutlinedButton(onPressed: onPressed, child: label);
    }
    return OutlinedButton.icon(onPressed: onPressed, icon: icon!, label: label);
  }
}

class BookIconBadge extends StatelessWidget {
  final String abbreviation;
  final double size;

  const BookIconBadge({super.key, required this.abbreviation, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.goldDark.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                abbreviation,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TestamentHeader extends StatelessWidget {
  final String title;

  const TestamentHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
