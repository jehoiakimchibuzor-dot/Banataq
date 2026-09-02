import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Explicit [ColorScheme]s for light and dark.
///
/// Built from [AppColors] so the palette lives in exactly one place. The
/// schemes are fully explicit (no `fromSeed` at runtime) so the premium
/// surfaces remain deterministic across builds.
abstract final class AppColorScheme {
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD4AF5A), // Electric Blue
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),
    inversePrimary: Color(0xFFE2C477),
    secondary: Color(0xFFD4AF5A),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF1E3A8A),
    onSecondaryContainer: Color(0xFFDBEAFE),
    tertiary: Color(0xFFE2C477),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF1E3A8A),
    onTertiaryContainer: Color(0xFFDBEAFE),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),
    surface: Color(0xFF070B14),
    onSurface: Color(0xFFF8FAFC),
    surfaceContainerLowest: Color(0xFF070B14),
    surfaceContainerLow: Color(0xFF070B14),
    surfaceContainer: Color(0xFF070B14),
    surfaceContainerHigh: Color(0xFF1A2535),
    surfaceContainerHighest: Color(0xFF202938),
    onSurfaceVariant: Color(0xFF98A2B3),
    outline: Color(0xFF2D3748),
    outlineVariant: Color(0xFF202938),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFF8FAFC),
    onInverseSurface: Color(0xFF070B14),
    surfaceTint: Color(0xFFD4AF5A),
  );

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFC89B3C),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    inversePrimary: Color(0xFFD4AF5A),
    secondary: Color(0xFFD4AF5A),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFDBEAFE),
    onSecondaryContainer: Color(0xFF1E3A8A),
    tertiary: Color(0xFFE2C477),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFDBEAFE),
    onTertiaryContainer: Color(0xFF1E3A8A),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F7F9),
    surfaceContainer: Color(0xFFF0F1F3),
    surfaceContainerHigh: Color(0xFFE9EAED),
    surfaceContainerHighest: Color(0xFFE2E3E7),
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    outline: Color(0xFF9AA0AB),
    outlineVariant: AppColors.lightOutline,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.lightOnSurface,
    onInverseSurface: Color(0xFFF7F7F9),
    surfaceTint: AppColors.brand,
  );
}