import '../../../../core/errors/app_result.dart';
import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppResult<AppSettings>> getSettings();

  Future<AppResult<AppSettings>> updateSettings(AppSettings settings);

  Future<AppResult<String>> exportData(String uid);

  Future<AppResult<void>> deleteAccountData(String uid);
}
