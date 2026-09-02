import '../../../../core/errors/app_result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

final class SignInWithGoogle {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  Future<AppResult<AuthUser>> call() {
    return _repository.signInWithGoogle();
  }
}
