import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class LoadProfile extends ProfileEvent {
  final String uid;
  const LoadProfile(this.uid);

  @override
  List<Object?> get props => [uid];
}

final class UpdateProfileRequested extends ProfileEvent {
  final String displayName;
  final String username;
  final String country;
  final String language;
  final String? bio;

  const UpdateProfileRequested({
    required this.displayName,
    required this.username,
    required this.country,
    required this.language,
    this.bio,
  });

  @override
  List<Object?> get props => [displayName, username, country, language, bio];
}

final class UploadAvatarRequested extends ProfileEvent {
  final String uid;
  final String filePath;

  const UploadAvatarRequested({required this.uid, required this.filePath});

  @override
  List<Object?> get props => [uid, filePath];
}
