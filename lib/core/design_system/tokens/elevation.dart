/// Elevation scale.
///
/// Prefers *soft, spread* shadows over harsh drop shadows. In dark mode
/// shadows are almost imperceptible — depth comes from surface tone instead.
abstract final class AppElevation {
  /// Flat surfaces.
  static const double none = 0;

  /// Cards resting on the canvas.
  static const double xs = 1;

  /// Slightly raised controls.
  static const double sm = 2;

  /// Floating elements, FABs.
  static const double md = 4;

  /// Overlays, bottom sheets.
  static const double lg = 8;

  /// Modals, search overlays.
  static const double xl = 16;

  /// Highest level — confirm dialogs.
  static const double xxl = 24;
}
