import '../../../../core/errors/app_result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../datasources/profile_local_datasource.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final ConnectivityService connectivityService;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  });

  @override
  Future<AppResult<UserProfile>> getProfile(String uid) async {
    final connected = await connectivityService.isConnected;

    if (connected) {
      final result = await remoteDataSource.getProfile(uid);
      if (result is Success<UserProfile>) {
        await localDataSource.cacheProfile(result.data);
      }
      return result;
    }

    return localDataSource.getCachedProfile();
  }

  @override
  Future<AppResult<UserProfile>> createProfile(UserProfile profile) async {
    final result = await remoteDataSource.createProfile(profile);
    if (result is Success<UserProfile>) {
      await localDataSource.cacheProfile(result.data);
    }
    return result;
  }

  @override
  Future<AppResult<UserProfile>> updateProfile(UserProfile profile) async {
    final connected = await connectivityService.isConnected;

    await localDataSource.cacheProfile(profile);

    if (connected) {
      return remoteDataSource.updateProfile(profile);
    }

    return Success(profile);
  }

  @override
  Future<AppResult<String>> uploadAvatar({
    required String uid,
    required String filePath,
  }) async {
    return remoteDataSource.uploadAvatar(uid: uid, filePath: filePath);
  }
}
