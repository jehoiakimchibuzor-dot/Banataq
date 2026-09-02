import '../../../../core/errors/app_result.dart';
import '../repositories/auth_repository.dart';

final class SignOut {
  final AuthRepository _repository;

  SignOut(this._repository);

  Future<AppResult<void>> call() {
    return _repository.signOut();
  }
}
