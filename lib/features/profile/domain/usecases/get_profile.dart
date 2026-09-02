import '../../../../core/errors/app_result.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

final class GetProfile {
  final ProfileRepository _repository;

  GetProfile(this._repository);

  Future<AppResult<UserProfile>> call(String uid) {
    return _repository.getProfile(uid);
  }
}
