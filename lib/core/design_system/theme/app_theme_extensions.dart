import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/durations.dart';
import '../tokens/elevation.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// Theme extensions registered on [ThemeData]. Widgets read values through
/// the [AppThemeContext] accessors so *no* component hardcodes a value.
///
/// Everything here is derived from the raw tokens.
abstract final class AppThemeExtensions {
  static List<ThemeExtension<dynamic>> all(Brightness brightness) => [
        AppSpacingTheme(brightness: brightness),
        AppRadiusTheme(brightness: brightness),
        AppDurationsTheme(brightness: brightness),
        AppMotionTheme(brightness: brightness),
        AppElevationTheme(brightness: brightness),
        AppShadowsTheme(brightness: brightness),
        AppSemanticColors(brightness: brightness),
      ];
}

final class AppSpacingTheme extends ThemeExtension<AppSpacingTheme> {
  const AppSpacingTheme({required this.brightness})
      : hairline = AppSpacing.hairline,
        xxs = AppSpacing.xxs,
        xs = AppSpacing.xs,
        sm = AppSpacing.sm,
        md = AppSpacing.md,
        lg = AppSpacing.lg,
        xl = AppSpacing.xl,
        xxl = AppSpacing.xxl,
        xxxl = AppSpacing.xxxl,
        huge = AppSpacing.huge;

  final Brightness brightness;
  final double hairline;
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double huge;

  EdgeInsets all(double value) => EdgeInsets.all(value);

  @override
  AppSpacingTheme copyWith({Brightness? brightness}) => this;

  @override
  AppSpacingTheme lerp(covariant AppSpacingTheme? other, double t) => this;
}

final class AppRadiusTheme extends ThemeExtension<AppRadiusTheme> {
  const AppRadiusTheme({required this.brightness})
      : xs = AppRadius.xs,
        sm = AppRadius.sm,
        md = AppRadius.md,
        lg = AppRadius.lg,
        xl = AppRadius.xl,
        xxl = AppRadius.xxl,
        xxxl = AppRadius.xxxl,
        pill = AppRadius.pill;

  final Brightness brightness;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double pill;

  BorderRadius get allXs => BorderRadius.circular(xs);
  BorderRadius get allSm => BorderRadius.circular(sm);
  BorderRadius get allMd => BorderRadius.circular(md);
  BorderRadius get allLg => BorderRadius.circular(lg);
  BorderRadius get allXl => BorderRadius.circular(xl);
  BorderRadius get allXxl => BorderRadius.circular(xxl);
  BorderRadius get allXxxl => BorderRadius.circular(xxxl);

  @override
  AppRadiusTheme copyWith({Brightness? brightness}) => this;

  @override
  AppRadiusTheme lerp(covariant AppRadiusTheme? other, double t) => this;
}

final class AppDurationsTheme extends ThemeExtension<AppDurationsTheme> {
  const AppDurationsTheme({required this.brightness})
      : fast = AppDurations.fast,
        normal = AppDurations.normal,
        medium = AppDurations.medium,
        slow = AppDurations.slow;

  final Brightness brightness;
  final Duration fast;
  final Duration normal;
  final Duration medium;
  final Duration slow;

  @override
  AppDurationsTheme copyWith({Brightness? brightness}) => this;

  @override
  AppDurationsTheme lerp(covariant AppDurationsTheme? other, double t) => this;
}

final class AppMotionTheme extends ThemeExtension<AppMotionTheme> {
  const AppMotionTheme({required this.brightness})
      : easeOutCubic = AppCurves.easeOutCubic,
        easeInOutCubic = AppCurves.easeInOutCubic,
        easeOutBack = AppCurves.easeOutBack,
        linear = AppCurves.linear;

  final Brightness brightness;
  final Curve easeOutCubic;
  final Curve easeInOutCubic;
  final Curve easeOutBack;
  final Curve linear;

  @override
  AppMotionTheme copyWith({Brightness? brightness}) => this;

  @override
  AppMotionTheme lerp(covariant AppMotionTheme? other, double t) => this;
}

final class AppElevationTheme extends ThemeExtension<AppElevationTheme> {
  const AppElevationTheme({required this.brightness})
      : none = AppElevation.none,
        xs = AppElevation.xs,
        sm = AppElevation.sm,
        md = AppElevation.md,
        lg = AppElevation.lg,
        xl = AppElevation.xl,
        xxl = AppElevation.xxl;

  final Brightness brightness;
  final double none;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  @override
  AppElevationTheme copyWith({Brightness? brightness}) => this;

  @override
  AppElevationTheme lerp(covariant AppElevationTheme? other, double t) => this;
}

/// Soft, spread shadows. Dark mode shadows are near-invisible by design —
/// depth there comes from surface tones, not shadow.
final class AppShadowsTheme extends ThemeExtension<AppShadowsTheme> {
  AppShadowsTheme({required this.brightness})
      : xs = _shadow(brightness, 0x12, 1, 6),
        sm = _shadow(brightness, 0x1A, 2, 10),
        md = _shadow(brightness, 0x24, 4, 16),
        lg = _shadow(brightness, 0x2E, 8, 24),
        xl = _shadow(brightness, 0x38, 12, 40);

  final Brightness brightness;
  final List<BoxShadow> xs;
  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> xl;

  static List<BoxShadow> _shadow(Brightness brightness, int alpha, double y, double blur) {
    final color = Color(0x00000000).withValues(alpha: alpha / 255.0);
    return [BoxShadow(color: color, offset: Offset(0, y), blurRadius: blur)];
  }

  @override
  AppShadowsTheme copyWith({Brightness? brightness}) =>
      AppShadowsTheme(brightness: brightness ?? this.brightness);

  @override
  AppShadowsTheme lerp(covariant AppShadowsTheme? other, double t) => this;
}

/// Semantic colors that adapt to brightness. Used by badges, feedback
/// surfaces, tags and empty states.
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  AppSemanticColors({required this.brightness})
      : success = AppColors.success,
        warning = AppColors.warning,
        danger = AppColors.danger,
        info = AppColors.info,
        onSuccess = Colors.white,
        onWarning = Color(0xFF3B2A00),
        onDanger = Colors.white,
        onInfo = Color(0xFF083344),
        successContainer = Color(0xFFD1FAE5),
        warningContainer = Color(0xFFFEF3C7),
        dangerContainer = Color(0xFFFEE2E2),
        infoContainer = Color(0xFFCFFAFE);

  final Brightness brightness;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color onSuccess;
  final Color onWarning;
  final Color onDanger;
  final Color onInfo;
  final Color successContainer;
  final Color warningContainer;
  final Color dangerContainer;
  final Color infoContainer;

  Color containerFor(StatusTone tone) => switch (tone) {
        StatusTone.success => successContainer,
        StatusTone.warning => warningContainer,
        StatusTone.danger => dangerContainer,
        StatusTone.info => infoContainer,
      };

  Color foregroundFor(StatusTone tone) => switch (tone) {
        StatusTone.success => success,
        StatusTone.warning => warning,
        StatusTone.danger => danger,
        StatusTone.info => info,
      };

  @override
  AppSemanticColors copyWith({Brightness? brightness}) => this;

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) => this;
}

/// Shared semantic tone used across badges, tags and chips.
enum StatusTone { success, warning, danger, info }
