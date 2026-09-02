import 'package:flutter/material.dart';
import 'app_theme_extensions.dart';

/// Ergonomie accessors so components can read design tokens without
/// hardcoding values.
extension AppThemeContext on BuildContext {
  AppSpacingTheme get appSpacing => Theme.of(this).extension<AppSpacingTheme>()!;

  AppRadiusTheme get appRadius => Theme.of(this).extension<AppRadiusTheme>()!;

  AppDurationsTheme get appDurations => Theme.of(this).extension<AppDurationsTheme>()!;

  AppMotionTheme get appMotion => Theme.of(this).extension<AppMotionTheme>()!;

  AppElevationTheme get appElevation => Theme.of(this).extension<AppElevationTheme>()!;

  AppShadowsTheme get appShadows => Theme.of(this).extension<AppShadowsTheme>()!;

  AppSemanticColors get appSemantics => Theme.of(this).extension<AppSemanticColors>()!;
}
