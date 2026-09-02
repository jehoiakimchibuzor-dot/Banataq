/// Animation duration scale.
///
/// Fast and confident. Micro-interactions stay at [fast]; screen-level
/// transitions use [medium]; ambient motion never exceeds [slow].
abstract final class AppDurations {
  /// 150ms — micro-interactions (button states, ripple-adjacent feedback).
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — default for component entrances and small transitions.
  static const Duration normal = Duration(milliseconds: 250);

  /// 350ms — card entrances, tab changes, sheet reveals.
  static const Duration medium = Duration(milliseconds: 350);

  /// 500ms — hero transitions, full-page fades.
  static const Duration slow = Duration(milliseconds: 500);
}
