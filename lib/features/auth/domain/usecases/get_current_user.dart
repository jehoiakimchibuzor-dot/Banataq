import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

final class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  Future<AuthUser?> call() {
    return _repository.getCurrentUser();
  }
}
