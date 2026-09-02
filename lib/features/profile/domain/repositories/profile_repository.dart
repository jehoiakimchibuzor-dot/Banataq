import '../../../../core/errors/app_result.dart';
import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<AppResult<UserProfile>> getProfile(String uid);

  Future<AppResult<UserProfile>> createProfile(UserProfile profile);

  Future<AppResult<UserProfile>> updateProfile(UserProfile profile);

  Future<AppResult<String>> uploadAvatar({
    required String uid,
    required String filePath,
  });
}
