import '../../../../core/errors/app_result.dart';
import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<AppResult<AuthUser>> signInWithGoogle();

  Future<AppResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppResult<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppResult<AuthUser>> signInAnonymously();

  Future<AppResult<void>> signOut();

  Future<AppResult<void>> resetPassword(String email);

  Future<AppResult<void>> deleteAccount();

  Future<AppResult<AuthUser>> linkWithGoogle();

  Future<AuthUser?> getCurrentUser();
}
