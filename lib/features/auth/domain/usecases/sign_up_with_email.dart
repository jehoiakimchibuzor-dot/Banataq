import '../../../../core/errors/app_result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

final class SignUpWithEmail {
  final AuthRepository _repository;

  SignUpWithEmail(this._repository);

  Future<AppResult<AuthUser>> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
