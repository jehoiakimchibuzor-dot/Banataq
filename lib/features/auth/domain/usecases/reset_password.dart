import '../../../../core/errors/app_result.dart';
import '../repositories/auth_repository.dart';

final class ResetPassword {
  final AuthRepository _repository;

  ResetPassword(this._repository);

  Future<AppResult<void>> call(String email) {
    return _repository.resetPassword(email);
  }
}
