import '../../../../core/errors/app_result.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/settings_remote_datasource.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;
  final SettingsRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  SettingsRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
  });

  @override
  Future<AppResult<AppSettings>> getSettings() async {
    return localDataSource.getSettings();
  }

  @override
  Future<AppResult<AppSettings>> updateSettings(AppSettings settings) async {
    await localDataSource.saveSettings(settings);

    final connected = await connectivityService.isConnected;
    if (connected) {
      await remoteDataSource.saveSettings('current_user', settings.toJson());
    }

    return Success(settings);
  }

  @override
  Future<AppResult<String>> exportData(String uid) async {
    final connected = await connectivityService.isConnected;
    if (!connected) {
      return Failure(const NetworkError('Cannot export data while offline'));
    }
    return remoteDataSource.exportData(uid);
  }

  @override
  Future<AppResult<void>> deleteAccountData(String uid) async {
    final connected = await connectivityService.isConnected;
    if (!connected) {
      return Failure(const NetworkError('Cannot delete account while offline'));
    }
    final result = await remoteDataSource.deleteAccountData(uid);
    if (result is Success<void>) {
      await localDataSource.clearAll();
    }
    return result;
  }
}
