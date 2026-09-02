import '../../../../core/errors/app_result.dart';
import '../repositories/settings_repository.dart';

final class ExportData {
  final SettingsRepository _repository;

  ExportData(this._repository);

  Future<AppResult<String>> call(String uid) {
    return _repository.exportData(uid);
  }
}
