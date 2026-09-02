/// Corner radius scale.
///
/// Large rounded corners are a core Banataq trait — they make surfaces feel
/// premium and approachable (Notion / Arc style) while remaining native.
abstract final class AppRadius {
  /// 8dp — controls, small elements.
  static const double xs = 8;

  /// 12dp — chips, compact inputs.
  static const double sm = 12;

  /// 16dp — standard inputs, small cards.
  static const double md = 16;

  /// 20dp — cards, dialogs.
  static const double lg = 20;

  /// 24dp — large panels, search overlays.
  static const double xl = 24;

  /// 28dp — floating panels, composer surfaces.
  static const double xxl = 28;

  /// 32dp — hero surfaces.
  static const double xxxl = 32;

  /// Fully rounded — pills, tags, badges.
  static const double pill = 999;
}
