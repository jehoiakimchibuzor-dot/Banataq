/// 8dp-based spacing scale.
///
/// Use these everywhere. Components derive padding/margins from the
/// [AppSpacingTheme] exposed on `Theme.of(context)`, which in turn is built
/// from these raw values.
abstract final class AppSpacing {
  /// 2dp — hairline gaps.
  static const double hairline = 2;

  /// 4dp — tightest internal gap.
  static const double xxs = 4;

  /// 8dp — base unit.
  static const double xs = 8;

  /// 12dp — compact gaps between related elements.
  static const double sm = 12;

  /// 16dp — standard padding.
  static const double md = 16;

  /// 24dp — section padding.
  static const double lg = 24;

  /// 32dp — large section padding.
  static const double xl = 32;

  /// 40dp — screen edge padding (wide layouts).
  static const double xxl = 40;

  /// 48dp — hero spacing.
  static const double xxxl = 48;

  /// 64dp — top-level rhythm spacing.
  static const double huge = 64;
}
