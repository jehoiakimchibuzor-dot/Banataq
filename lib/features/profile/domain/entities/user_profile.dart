import 'package:equatable/equatable.dart';

enum UserPersona { student, business, creator, general }

enum SubscriptionTier { free, premium }

extension UserPersonaLabel on UserPersona {
  String get label {
    return switch (this) {
      UserPersona.student => 'Student',
      UserPersona.business => 'Business Owner',
      UserPersona.creator => 'Creator',
      UserPersona.general => 'General User',
    };
  }
}

final class UserProfile extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String? bio;
  final String country;
  final String language;
  final String timezone;
  final UserPersona persona;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.bio,
    this.country = 'Nigeria',
    this.language = 'en',
    this.timezone = 'Africa/Lagos',
    this.persona = UserPersona.general,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? photoUrl,
    String? bio,
    String? country,
    String? language,
    String? timezone,
    UserPersona? persona,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      persona: persona ?? this.persona,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': username,
        'photoUrl': photoUrl,
        'bio': bio,
        'country': country,
        'language': language,
        'timezone': timezone,
        'persona': persona.name,
        'subscriptionTier': subscriptionTier.name,
        'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      country: json['country'] as String? ?? 'Nigeria',
      language: json['language'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'Africa/Lagos',
      persona: UserPersona.values.firstWhere(
        (e) => e.name == json['persona'],
        orElse: () => UserPersona.general,
      ),
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (e) => e.name == json['subscriptionTier'],
        orElse: () => SubscriptionTier.free,
      ),
      subscriptionExpiry: json['subscriptionExpiry'] != null
          ? DateTime.parse(json['subscriptionExpiry'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        username,
        photoUrl,
        bio,
        country,
        language,
        timezone,
        persona,
        subscriptionTier,
        subscriptionExpiry,
        createdAt,
        updatedAt,
      ];
}
