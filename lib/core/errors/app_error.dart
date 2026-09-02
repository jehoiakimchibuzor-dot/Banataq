sealed class AppError {
  const AppError();

  String get message;
}

final class NetworkError extends AppError {
  final String? details;
  const NetworkError([this.details]);

  @override
  String get message => details ?? 'No internet connection';
}

final class ServerError extends AppError {
  final int? statusCode;
  final String? details;
  const ServerError({this.statusCode, this.details});

  @override
  String get message => details ?? 'Server error (${statusCode ?? 0})';
}

final class AuthError extends AppError {
  final String? details;
  const AuthError([this.details]);

  @override
  String get message => details ?? 'Authentication failed';
}

final class ValidationError extends AppError {
  final String? details;
  const ValidationError([this.details]);

  @override
  String get message => details ?? 'Invalid input';
}

final class NotFoundError extends AppError {
  final String? details;
  const NotFoundError([this.details]);

  @override
  String get message => details ?? 'Resource not found';
}

final class CacheError extends AppError {
  final String? details;
  const CacheError([this.details]);

  @override
  String get message => details ?? 'Cache operation failed';
}

final class PermissionDeniedError extends AppError {
  final String? details;
  const PermissionDeniedError([this.details]);

  @override
  String get message => details ?? 'Permission denied';
}

final class UnknownError extends AppError {
  final String? details;
  const UnknownError([this.details]);

  @override
  String get message => details ?? 'An unexpected error occurred';
}
