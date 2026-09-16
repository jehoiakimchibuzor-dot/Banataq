import 'dart:async';

import 'package:banataq/core/di/injection_container.dart' as di;
import 'package:banataq/core/errors/app_error.dart';
import 'package:banataq/core/errors/app_result.dart';
import 'package:banataq/services/assistant_service.dart';
import 'package:banataq/services/storage_service.dart';
import 'package:banataq/features/auth/domain/entities/auth_user.dart';
import 'package:banataq/features/auth/domain/repositories/auth_repository.dart';
import 'package:banataq/features/auth/domain/usecases/delete_account.dart';
import 'package:banataq/features/auth/domain/usecases/get_current_user.dart';
import 'package:banataq/features/auth/domain/usecases/reset_password.dart';
import 'package:banataq/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:banataq/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:banataq/features/auth/domain/usecases/sign_out.dart';
import 'package:banataq/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:banataq/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:banataq/features/profile/domain/entities/user_profile.dart';
import 'package:banataq/features/profile/domain/repositories/profile_repository.dart';
import 'package:banataq/features/profile/domain/usecases/get_profile.dart';
import 'package:banataq/features/profile/domain/usecases/initialize_profile.dart';
import 'package:banataq/features/profile/domain/usecases/update_profile.dart';
import 'package:banataq/features/profile/domain/usecases/upload_avatar.dart';
import 'package:banataq/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:banataq/features/settings/domain/entities/app_settings.dart';
import 'package:banataq/features/settings/domain/repositories/settings_repository.dart';
import 'package:banataq/features/settings/domain/usecases/delete_account_data.dart';
import 'package:banataq/features/settings/domain/usecases/export_data.dart';
import 'package:banataq/features/settings/domain/usecases/get_settings.dart';
import 'package:banataq/features/settings/domain/usecases/update_settings.dart';
import 'package:banataq/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/features/workspace/services/workspace_service.dart';

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  final AuthUser? currentUser;

  final _authStateController = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  Future<AppResult<AuthUser>> signInWithGoogle() async {
    return Failure(AuthError());
  }

  @override
  Future<AppResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return Failure(AuthError());
  }

  @override
  Future<AppResult<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return Failure(AuthError());
  }

  @override
  Future<AppResult<AuthUser>> signInAnonymously() async {
    return Failure(AuthError());
  }

  @override
  Future<AppResult<void>> signOut() async {
    return const Success(null);
  }

  @override
  Future<AppResult<void>> resetPassword(String email) async {
    return const Success(null);
  }

  @override
  Future<AppResult<void>> deleteAccount() async {
    return const Success(null);
  }

  @override
  Future<AppResult<AuthUser>> linkWithGoogle() async {
    return Failure(AuthError());
  }

  @override
  Future<AuthUser?> getCurrentUser() async => currentUser;
}

final class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<AppResult<AppSettings>> getSettings() async {
    return const Success(AppSettings());
  }

  @override
  Future<AppResult<AppSettings>> updateSettings(AppSettings settings) async {
    return Success(settings);
  }

  @override
  Future<AppResult<String>> exportData(String uid) async {
    return const Success('{}');
  }

  @override
  Future<AppResult<void>> deleteAccountData(String uid) async {
    return const Success(null);
  }
}

final class FakeProfileRepository implements ProfileRepository {
  @override
  Future<AppResult<UserProfile>> getProfile(String uid) async {
    return Failure(NotFoundError());
  }

  @override
  Future<AppResult<UserProfile>> createProfile(UserProfile profile) async {
    return Success(profile);
  }

  @override
  Future<AppResult<UserProfile>> updateProfile(UserProfile profile) async {
    return Success(profile);
  }

  @override
  Future<AppResult<String>> uploadAvatar({
    required String uid,
    required String filePath,
  }) async {
    return const Success('https://example.com/avatar.png');
  }
}

Future<void> initTestDependencies({AuthUser? currentUser}) async {
  await di.sl.reset();

  final authRepository = FakeAuthRepository(currentUser: currentUser);
  final settingsRepository = FakeSettingsRepository();
  final profileRepository = FakeProfileRepository();

  di.sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      signInWithGoogle: SignInWithGoogle(authRepository),
      signInWithEmail: SignInWithEmail(authRepository),
      signUpWithEmail: SignUpWithEmail(authRepository),
      signOut: SignOut(authRepository),
      resetPassword: ResetPassword(authRepository),
      getCurrentUser: GetCurrentUser(authRepository),
      deleteAccount: DeleteAccount(authRepository),
      authRepository: authRepository,
    ),
  );

  di.sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      getSettings: GetSettings(settingsRepository),
      updateSettings: UpdateSettings(settingsRepository),
      exportData: ExportData(settingsRepository),
      deleteAccountData: DeleteAccountData(settingsRepository),
    ),
  );

  di.sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getProfile: GetProfile(profileRepository),
      updateProfile: UpdateProfile(profileRepository),
      uploadAvatar: UploadAvatar(profileRepository),
    ),
  );

  di.sl.registerLazySingleton<InitializeProfile>(
    () => InitializeProfile(profileRepository),
  );

  di.sl.registerLazySingleton<StorageService>(() => StorageService());
  di.sl.registerLazySingleton<AssistantService>(() => AssistantService(storage: di.sl<StorageService>()));
  di.sl.registerLazySingleton<WorkspaceRepository>(
    () => MockWorkspaceRepository(service: MockWorkspaceService(seed: false)),
  );
}
