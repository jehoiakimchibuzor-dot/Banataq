import '../../../../core/errors/app_result.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

final class UpdateSettings {
  final SettingsRepository _repository;

  UpdateSettings(this._repository);

  Future<AppResult<AppSettings>> call(AppSettings settings) {
    return _repository.updateSettings(settings);
  }
}
