import '../../../../core/errors/app_result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

final class SignInWithEmail {
  final AuthRepository _repository;

  SignInWithEmail(this._repository);

  Future<AppResult<AuthUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}
