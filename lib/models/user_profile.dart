enum UserPersona { student, business, creator, general }

extension UserPersonaLabel on UserPersona {
  String get label {
    switch (this) {
      case UserPersona.student:
        return 'Student';
      case UserPersona.business:
        return 'Business Owner';
      case UserPersona.creator:
        return 'Creator';
      case UserPersona.general:
        return 'General User';
    }
  }

  String get description {
    switch (this) {
      case UserPersona.student:
        return 'Exam help, notes, assignments, study plans';
      case UserPersona.business:
        return 'Captions, product descriptions, customer replies';
      case UserPersona.creator:
        return 'Scripts, captions, post ideas, content';
      case UserPersona.general:
        return 'Everyday questions, translations, summaries';
    }
  }
}

class UserProfile {
  final UserPersona persona;
  final DateTime createdAt;

  const UserProfile({required this.persona, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'persona': persona.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    persona: UserPersona.values.firstWhere(
      (e) => e.name == json['persona'],
      orElse: () => UserPersona.general,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
