import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/app_result.dart';

final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle signInWithGoogle;
  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final SignOut signOut;
  final ResetPassword resetPassword;
  final GetCurrentUser getCurrentUser;
  final DeleteAccount deleteAccount;
  final AuthRepository authRepository;
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthBloc({
    required this.signInWithGoogle,
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signOut,
    required this.resetPassword,
    required this.getCurrentUser,
    required this.deleteAccount,
    required this.authRepository,
  }) : super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<SignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = authRepository.authStateChanges.listen((user) {
      add(AuthStateChanged(user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = await getCurrentUser();
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await signInWithGoogle();
    if (result is Success<AuthUser>) {
      emit(AuthState.authenticated(result.data));
    } else {
      emit(AuthState.error((result as Failure).error.message));
    }
  }

  Future<void> _onSignInWithEmailRequested(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await signInWithEmail(
      email: event.email,
      password: event.password,
    );
    if (result is Success<AuthUser>) {
      emit(AuthState.authenticated(result.data));
    } else {
      emit(AuthState.error((result as Failure).error.message));
    }
  }

  Future<void> _onSignUpWithEmailRequested(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await signUpWithEmail(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    if (result is Success<AuthUser>) {
      emit(AuthState.authenticated(result.data));
    } else {
      emit(AuthState.error((result as Failure).error.message));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await signOut();
    if (result is Success<void>) {
      emit(const AuthState.unauthenticated());
    } else {
      emit(AuthState.error((result as Failure).error.message));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await resetPassword(event.email);
    if (result is Success<void>) {
      emit(state.copyWith(status: AuthStatus.unknown, errorMessage: null));
    } else {
      emit(AuthState.error((result as Failure).error.message));
    }
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await deleteAccount();
    if (result is Success<void>) {
      emit(const AuthState.unauthenticated());
    } else {
      emit(AuthState.error((result as Failure).error.message));
    }
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.status == AuthStatus.authenticated) {
      getCurrentUser().then((user) {
        if (user != null) {
          emit(AuthState.authenticated(user));
        }
      });
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
