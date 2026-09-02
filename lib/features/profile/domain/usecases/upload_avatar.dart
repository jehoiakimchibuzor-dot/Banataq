import '../../../../core/errors/app_result.dart';
import '../repositories/profile_repository.dart';

final class UploadAvatar {
  final ProfileRepository _repository;

  UploadAvatar(this._repository);

  Future<AppResult<String>> call({
    required String uid,
    required String filePath,
  }) {
    return _repository.uploadAvatar(uid: uid, filePath: filePath);
  }
}
