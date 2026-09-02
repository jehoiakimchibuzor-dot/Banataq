import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/app_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

final class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences _prefs;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required SharedPreferences sharedPreferences,
  }) : _prefs = sharedPreferences;

  @override
  Stream<AuthUser?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<AppResult<AuthUser>> signInWithGoogle() async {
    final result = await remoteDataSource.signInWithGoogle();
    if (result is Success<AuthUser>) {
      await _cacheUser(result.data);
    }
    return result;
  }

  @override
  Future<AppResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await remoteDataSource.signInWithEmail(
      email: email,
      password: password,
    );
    if (result is Success<AuthUser>) {
      await _cacheUser(result.data);
    }
    return result;
  }

  @override
  Future<AppResult<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await remoteDataSource.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    if (result is Success<AuthUser>) {
      await _cacheUser(result.data);
    }
    return result;
  }

  @override
  Future<AppResult<AuthUser>> signInAnonymously() async {
    final result = await remoteDataSource.signInAnonymously();
    if (result is Success<AuthUser>) {
      await _cacheUser(result.data);
    }
    return result;
  }

  @override
  Future<AppResult<void>> signOut() async {
    final result = await remoteDataSource.signOut();
    if (result is Success<void>) {
      await _prefs.remove('cached_uid');
      await _prefs.remove('cached_email');
    }
    return result;
  }

  @override
  Future<AppResult<void>> resetPassword(String email) async {
    return remoteDataSource.resetPassword(email);
  }

  @override
  Future<AppResult<void>> deleteAccount() async {
    final result = await remoteDataSource.deleteAccount();
    if (result is Success<void>) {
      await _prefs.remove('cached_uid');
      await _prefs.remove('cached_email');
    }
    return result;
  }

  @override
  Future<AppResult<AuthUser>> linkWithGoogle() async {
    final result = await remoteDataSource.linkWithGoogle();
    if (result is Success<AuthUser>) {
      await _cacheUser(result.data);
    }
    return result;
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    return remoteDataSource.getCurrentUser();
  }

  Future<void> _cacheUser(AuthUser user) async {
    await _prefs.setString('cached_uid', user.uid);
    if (user.email != null) {
      await _prefs.setString('cached_email', user.email!);
    }
  }
}
