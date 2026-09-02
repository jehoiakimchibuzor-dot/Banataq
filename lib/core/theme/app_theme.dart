import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

/// Backward-compatible theme entry point.
///
/// Delegates to the Banataq Design System. The public API is unchanged so
/// existing call sites (`AppTheme.fromMode(...)`) keep working untouched.
final class AppTheme {
  AppTheme._();

  static ThemeData dark() => AppThemeData.dark();

  static ThemeData light() => AppThemeData.light();

  static ThemeData fromMode(ThemeMode mode) => AppThemeData.fromMode(mode);
}
