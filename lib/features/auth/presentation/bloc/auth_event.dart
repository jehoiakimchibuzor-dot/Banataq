import 'package:equatable/equatable.dart';
import 'auth_state.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

final class SignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

final class SignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const SignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

final class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

final class DeleteAccountRequested extends AuthEvent {
  const DeleteAccountRequested();
}

final class AuthStateChanged extends AuthEvent {
  final AuthStatus status;

  const AuthStateChanged(this.status);

  @override
  List<Object?> get props => [status];
}
