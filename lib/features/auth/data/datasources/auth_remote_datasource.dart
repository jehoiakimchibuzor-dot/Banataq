import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/auth_user.dart';
import '../../../../core/errors/auth_exception_mapper.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/app_result.dart';

final class AuthRemoteDataSource {
  final FirebaseAuth _auth;

  AuthRemoteDataSource({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().map(_mapUser);
  }

  Future<AppResult<AuthUser>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final account = await googleSignIn.authenticate();
      final auth = account.authentication;

      if (auth.idToken == null) {
        return Failure(const AuthError('Failed to get Google ID token'));
      }

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user == null) {
        return Failure(const AuthError('Sign-in succeeded but no user returned'));
      }

      return Success(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return Failure(mapFirebaseAuthException(e));
    } on GoogleSignInException {
      return Failure(const AuthError('Google sign-in was cancelled or failed'));
    } catch (e) {
      return Failure(AuthError('Google sign-in failed: $e'));
    }
  }

  Future<AppResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) {
        return Failure(const AuthError('Sign-in failed'));
      }
      return Success(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return Failure(mapFirebaseAuthException(e));
    }
  }

  Future<AppResult<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) {
        return Failure(const AuthError('Account creation failed'));
      }

      await user.updateDisplayName(displayName);
      await user.reload();

      final updatedUser = _auth.currentUser;
      return Success(_mapUser(updatedUser)!);
    } on FirebaseAuthException catch (e) {
      return Failure(mapFirebaseAuthException(e));
    }
  }

  Future<AppResult<AuthUser>> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      final user = result.user;
      if (user == null) {
        return Failure(const AuthError('Anonymous sign-in failed'));
      }
      return Success(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return Failure(mapFirebaseAuthException(e));
    }
  }

  Future<AppResult<void>> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(AuthError('Sign-out failed: $e'));
    }
  }

  Future<AppResult<void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(mapFirebaseAuthException(e));
    }
  }

  Future<AppResult<void>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Failure(const AuthError('No user signed in'));
      }
      await user.delete();
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(mapFirebaseAuthException(e));
    }
  }

  Future<AppResult<AuthUser>> linkWithGoogle() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Failure(const AuthError('No user signed in'));
      }

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final account = await googleSignIn.authenticate();
      final auth = account.authentication;

      if (auth.idToken == null) {
        return Failure(const AuthError('Failed to get Google ID token'));
      }

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      final result = await currentUser.linkWithCredential(credential);
      final user = result.user;

      if (user == null) {
        return Failure(const AuthError('Account linking failed'));
      }

      return Success(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return Failure(mapFirebaseAuthException(e));
    } on GoogleSignInException {
      return Failure(const AuthError('Google linking was cancelled'));
    }
  }

  Future<AuthUser?> getCurrentUser() async {
    return _mapUser(_auth.currentUser);
  }

  AuthUser? _mapUser(User? firebaseUser) {
    if (firebaseUser == null) return null;
    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      isAnonymous: firebaseUser.isAnonymous,
    );
  }
}
