import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_in_with_email.dart';
import '../../features/auth/domain/usecases/sign_up_with_email.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/reset_password.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/delete_account.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/datasources/profile_local_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/domain/usecases/upload_avatar.dart';
import '../../features/profile/domain/usecases/initialize_profile.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/update_settings.dart';
import '../../features/settings/domain/usecases/export_data.dart';
import '../../features/settings/domain/usecases/delete_account_data.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../network/connectivity_service.dart';
import '../../features/sync/data/sync_service.dart';
import '../../services/assistant_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<AssistantService>(() => AssistantService());

  _initAuth();
  _initProfile();
  _initSettings();
  await _initSync();
}

Future<void> _initSync() async {
  final service = SyncService();
  await service.initialize(
    prefs: sl<SharedPreferences>(),
    connectivityService: sl<ConnectivityService>(),
  );
  sl.registerLazySingleton<SyncService>(() => service);
}

void _initAuth() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPassword(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => DeleteAccount(sl<AuthRepository>()));

  sl.registerFactory(
    () => AuthBloc(
      signInWithGoogle: sl<SignInWithGoogle>(),
      signInWithEmail: sl<SignInWithEmail>(),
      signUpWithEmail: sl<SignUpWithEmail>(),
      signOut: sl<SignOut>(),
      resetPassword: sl<ResetPassword>(),
      getCurrentUser: sl<GetCurrentUser>(),
      deleteAccount: sl<DeleteAccount>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
}

void _initProfile() {
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(),
  );

  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSource(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl<ProfileRemoteDataSource>(),
      localDataSource: sl<ProfileLocalDataSource>(),
      connectivityService: sl<ConnectivityService>(),
    ),
  );

  sl.registerLazySingleton(() => GetProfile(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfile(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UploadAvatar(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => InitializeProfile(sl<ProfileRepository>()));

  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl<GetProfile>(),
      updateProfile: sl<UpdateProfile>(),
      uploadAvatar: sl<UploadAvatar>(),
    ),
  );
}

void _initSettings() {
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSource(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSource(),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      localDataSource: sl<SettingsLocalDataSource>(),
      remoteDataSource: sl<SettingsRemoteDataSource>(),
      connectivityService: sl<ConnectivityService>(),
    ),
  );

  sl.registerLazySingleton(() => GetSettings(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => UpdateSettings(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => ExportData(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => DeleteAccountData(sl<SettingsRepository>()));

  sl.registerFactory(
    () => SettingsBloc(
      getSettings: sl<GetSettings>(),
      updateSettings: sl<UpdateSettings>(),
      exportData: sl<ExportData>(),
      deleteAccountData: sl<DeleteAccountData>(),
    ),
  );
}
