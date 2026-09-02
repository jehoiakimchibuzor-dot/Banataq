import 'app_error.dart';

sealed class AppResult<T> {
  const AppResult();
}

final class Success<T> extends AppResult<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends AppResult<T> {
  final AppError error;
  const Failure(this.error);
}
