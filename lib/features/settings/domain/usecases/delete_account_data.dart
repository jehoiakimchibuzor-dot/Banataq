import '../../../../core/errors/app_result.dart';
import '../repositories/settings_repository.dart';

final class DeleteAccountData {
  final SettingsRepository _repository;

  DeleteAccountData(this._repository);

  Future<AppResult<void>> call(String uid) {
    return _repository.deleteAccountData(uid);
  }
}
