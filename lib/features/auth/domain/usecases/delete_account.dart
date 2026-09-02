import '../../../../core/errors/app_result.dart';
import '../repositories/auth_repository.dart';

final class DeleteAccount {
  final AuthRepository _repository;

  DeleteAccount(this._repository);

  Future<AppResult<void>> call() {
    return _repository.deleteAccount();
  }
}
