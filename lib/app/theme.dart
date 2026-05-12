import 'package:bible_tracker/shared/widgets/app_ui.dart';
import 'package:flutter/material.dart';

ThemeData lightTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.goldDark,
    onPrimary: Colors.white,
    primaryContainer: AppColors.goldSoft,
    onPrimaryContainer: AppColors.text,
    secondary: AppColors.gold,
    onSecondary: AppColors.text,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      surfaceTintColor: AppColors.background,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.goldDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldDark,
        side: const BorderSide(color: AppColors.gold),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.goldSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.goldDark
              : AppColors.textMuted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.goldDark
              : AppColors.textMuted,
        ),
      ),
    ),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}

ThemeData darkTheme() => ThemeData(
  useMaterial3: true,
  colorSchemeSeed: AppColors.goldDark,
  brightness: Brightness.dark,
);
