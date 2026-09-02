import '../../../../core/errors/app_result.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

final class GetSettings {
  final SettingsRepository _repository;

  GetSettings(this._repository);

  Future<AppResult<AppSettings>> call() {
    return _repository.getSettings();
  }
}
