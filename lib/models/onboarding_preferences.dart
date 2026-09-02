import 'dart:convert';

/// Signature personalization collected right after onboarding, before auth.
///
/// Only two intents are captured:
/// 1) what the user wants Banataq to help accomplish (goals)
/// 2) how they want Banataq to help (assistance styles)
class OnboardingPreferences {
  /// Goal ids: learn, getThingsDone, build, create, communicate, figureThingsOut
  final Set<String> goals;

  /// Style ids: simple, direct, thinkTogether, creative, stepByStep
  final Set<String> assistanceStyles;

  const OnboardingPreferences({
    this.goals = const {},
    this.assistanceStyles = const {},
  });

  static const allGoals = <String>[
    'learn',
    'getThingsDone',
    'build',
    'create',
    'communicate',
    'figureThingsOut',
  ];

  static const allStyles = <String>[
    'simple',
    'direct',
    'thinkTogether',
    'creative',
    'stepByStep',
  ];

  bool get hasAnyGoal => goals.isNotEmpty;
  bool get hasAnyStyle => assistanceStyles.isNotEmpty;
  bool get isComplete => hasAnyGoal && hasAnyStyle;
  bool get isEmpty => goals.isEmpty && assistanceStyles.isEmpty;

  OnboardingPreferences copyWith({
    Set<String>? goals,
    Set<String>? assistanceStyles,
  }) {
    return OnboardingPreferences(
      goals: goals ?? this.goals,
      assistanceStyles: assistanceStyles ?? this.assistanceStyles,
    );
  }

  Map<String, dynamic> toJson() => {
        'goals': goals.toList()..sort(),
        'assistanceStyles': assistanceStyles.toList()..sort(),
      };

  factory OnboardingPreferences.fromJson(Map<String, dynamic> json) {
    final g = (json['goals'] as List?)?.cast<String>() ?? <String>[];
    final s =
        (json['assistanceStyles'] as List?)?.cast<String>() ?? <String>[];
    return OnboardingPreferences(
      goals: g.toSet(),
      assistanceStyles: s.toSet(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory OnboardingPreferences.decode(String raw) {
    return OnboardingPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Human-readable summary used on the Ready screen and for assistant context.
  String assistantContextLine() {
    final parts = <String>[];
    if (goals.contains('learn')) parts.add('learning-focused');
    if (goals.contains('getThingsDone')) parts.add('productivity-focused');
    if (goals.contains('build')) parts.add('business/building-focused');
    if (goals.contains('create')) parts.add('creation-focused');
    if (goals.contains('communicate')) parts.add('communication-focused');
    if (goals.contains('figureThingsOut')) parts.add('problem-solving');
    if (assistanceStyles.contains('simple')) parts.add('prefers simple explanations');
    if (assistanceStyles.contains('direct')) parts.add('prefers direct answers');
    if (assistanceStyles.contains('thinkTogether')) parts.add('likes to think together');
    if (assistanceStyles.contains('creative')) parts.add('wants creative, alternative ideas');
    if (assistanceStyles.contains('stepByStep')) parts.add('prefers step-by-step guidance');
    return parts.join(', ');
  }
}
