import 'dart:ui';

/// Raw color palette for the Banataq design system.
///
/// These are the single source of truth. The theme layer maps them into
/// `ColorScheme` and `ThemeExtension` values so widgets never reference
/// hardcoded colors.
abstract final class AppColors {
  /// Electric Blue — primary brand, intelligent accent
  static const Color brand = Color(0xFFD4AF5A); // Bright Royal Blue — PRIMARY
  static const Color brandStrong = Color(0xFFC89B3C);
  static const Color brandSoft = Color(0xFFE2C477); // Bright
  static const Color brandHighlight = Color(0xFFF4D98B); // Light highlight
  static const Color brandSoftLight = Color(0xFF8FB0FF); // Soft
  static const Color brandContainerLight = Color(0xFFDBEAFE);
  static const Color brandContainerDark = Color(0xFF1E3A8A);
  static const Color gold = Color(0xFFD4AF5A); // alias kept for compat — now blue
  static const Color goldStrong = Color(0xFFC89B3C);
  static const Color goldSoft = Color(0xFFE2C477);
  static const Color goldContainerLight = Color(0xFFDBEAFE);
  static const Color goldContainerDark = Color(0xFF1E3A8A);

  /// Semantic: success / positive.
  static const Color success = Color(0xFF10B981);

  /// Semantic: warning / caution.
  static const Color warning = Color(0xFFF59E0B);

  /// Semantic: danger / destructive.
  static const Color danger = Color(0xFFEF4444);

  /// Semantic: informational.
  static const Color info = Color(0xFF06B6D4);

  /// --- Dark — Premium #080B12 / #101521 ---
  static const Color darkScaffold = Color(0xFF070B14); // App background
  static const Color darkSurface = Color(0xFF070B14);
  static const Color darkSurfaceElevated = Color(0xFF070B14); // Cards
  static const Color darkSurfaceContainer = Color(0xFF070B14);
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceVariant = Color(0xFF98A2B3);
  static const Color darkOutline = Color(0xFF202938);
  static const Color darkOutlineStrong = Color(0xFF2D3748);

  /// --- Light — #FAFAFC / #FFFFFF ---
  static const Color lightScaffold = Color(0xFFFAFAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF1F5F9);
  static const Color lightOnSurface = Color(0xFF101828);
  static const Color lightOnSurfaceVariant = Color(0xFF667085);
  static const Color lightOutline = Color(0xFFE4E7EC);
  static const Color lightSkeleton = Color(0xFFE4E7EF);
  static const Color lightSkeletonShimmer = Color(0xFFD7DCE6);
  static const Color darkSkeleton = Color(0xFF252D3A);
  static const Color darkSkeletonShimmer = Color(0xFF303A4A);

  /// White overlays used on dark surfaces (respects dark tint).
  static const Color whiteHigh = Color(0xF2FFFFFF);
  static const Color whiteMedium = Color(0x99FFFFFF);
  static const Color whiteLow = Color(0x66FFFFFF);
}