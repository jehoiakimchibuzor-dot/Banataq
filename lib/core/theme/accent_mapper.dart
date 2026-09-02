import 'package:flutter/material.dart';
import '../design_system/tokens/accent_theme.dart';

ColorScheme schemeFor(AccentTheme accent, Brightness b, AccentIntensity intensity) {
  final t = kAccentTokens[accent]!;
  final isDark = b == Brightness.dark;
  // intensity modulates glow/primary saturation
  final primary = intensity == AccentIntensity.vibrant ? t.bright : intensity == AccentIntensity.soft ? Color.lerp(t.primary, Colors.white, 0.15)! : t.primary;
  final glow = t.glow;
  if (isDark) {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: primary, onPrimary: Colors.white,
      primaryContainer: t.gradientStart, onPrimaryContainer: Colors.white,
      secondary: t.secondary, onSecondary: Colors.white,
      secondaryContainer: t.gradientStart, onSecondaryContainer: Colors.white,
      tertiary: t.bright, onTertiary: Colors.white,
      tertiaryContainer: t.gradientStart, onTertiaryContainer: Colors.white,
      error: const Color(0xFFEF4444), onError: Colors.white,
      errorContainer: const Color(0xFF7F1D1D), onErrorContainer: const Color(0xFFFECACA),
      surface: t.darkBg, onSurface: const Color(0xFFF8FAFC),
      surfaceContainerLowest: t.darkBg, surfaceContainerLow: t.darkSurface, surfaceContainer: t.darkCard,
      surfaceContainerHigh: t.darkCard, surfaceContainerHighest: t.darkCard,
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: const Color(0xFF253553), outlineVariant: const Color(0xFF1E2A3D),
      shadow: Colors.black, scrim: Colors.black,
      inverseSurface: const Color(0xFFF8FAFC), onInverseSurface: t.darkBg,
      surfaceTint: primary,
    );
  } else {
    return ColorScheme(
      brightness: Brightness.light,
      primary: primary, onPrimary: Colors.white,
      primaryContainer: t.soft, onPrimaryContainer: t.primary,
      secondary: t.secondary, onSecondary: Colors.white,
      secondaryContainer: t.soft, onSecondaryContainer: t.primary,
      tertiary: t.bright, onTertiary: Colors.white,
      tertiaryContainer: t.soft, onTertiaryContainer: t.primary,
      error: const Color(0xFFEF4444), onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2), onErrorContainer: const Color(0xFF7F1D1D),
      surface: t.lightBg, onSurface: const Color(0xFF0F172A),
      surfaceContainerLowest: Colors.white, surfaceContainerLow: t.lightSurface, surfaceContainer: t.lightCard,
      surfaceContainerHigh: t.lightSurface, surfaceContainerHighest: t.lightSurface,
      onSurfaceVariant: const Color(0xFF64748B),
      outline: const Color(0xFFCBD5E1), outlineVariant: const Color(0xFFE2E8F0),
      shadow: Colors.black, scrim: Colors.black,
      inverseSurface: const Color(0xFF0F172A), onInverseSurface: Colors.white,
      surfaceTint: primary,
    );
  }
}
