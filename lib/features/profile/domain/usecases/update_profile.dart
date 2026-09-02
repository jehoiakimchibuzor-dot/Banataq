import '../../../../core/errors/app_result.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

final class UpdateProfile {
  final ProfileRepository _repository;

  UpdateProfile(this._repository);

  Future<AppResult<UserProfile>> call(UserProfile profile) {
    return _repository.updateProfile(profile);
  }
}
