import 'package:firebase_auth/firebase_auth.dart';
import 'app_error.dart';

AppError mapFirebaseAuthException(FirebaseAuthException e) {
  return switch (e.code) {
    'user-not-found' => const AuthError('No account found with this email'),
    'wrong-password' => const AuthError('Incorrect password'),
    'invalid-email' => const AuthError('Invalid email address'),
    'user-disabled' => const AuthError('This account has been disabled'),
    'email-already-in-use' => const AuthError('An account already exists with this email'),
    'operation-not-allowed' => const AuthError('This sign-in method is not enabled'),
    'weak-password' => const AuthError('Password must be at least 6 characters'),
    'invalid-credential' => const AuthError('Invalid email or password'),
    'account-exists-with-different-credential' =>
      const AuthError('An account already exists with a different sign-in method'),
    'requires-recent-login' => const AuthError('Please sign in again before deleting your account'),
    'network-request-failed' => const NetworkError('Network error. Check your connection.'),
    _ => AuthError(e.message ?? 'Authentication failed'),
  };
}
