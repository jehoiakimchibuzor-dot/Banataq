import '../../../../core/errors/app_result.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

final class InitializeProfile {
  final ProfileRepository _repository;

  InitializeProfile(this._repository);

  Future<AppResult<UserProfile>> call({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final profile = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName.isNotEmpty ? displayName : 'User',
      username: _generateUsername(email, uid),
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _repository.createProfile(profile);
  }

  String _generateUsername(String email, String uid) {
    final prefix = email.isNotEmpty ? email.split('@').first : 'user';
    return '${prefix}_${uid.substring(0, 6)}';
  }
}
