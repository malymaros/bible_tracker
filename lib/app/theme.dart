import 'package:flutter/material.dart';

// Deep indigo — scholarly and reverent, suitable for a sacred text application.
const _seedColor = Color(0xFF1A237E);

ThemeData lightTheme() => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: Brightness.light,
    );

ThemeData darkTheme() => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: Brightness.dark,
    );
