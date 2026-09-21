/// A failure that can be shown or logged without exposing implementation details.
final class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

/// Result for boundaries such as storage, billing and platform integrations.
sealed class AppResult<T> {
  const AppResult();
}

final class Success<T> extends AppResult<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends AppResult<T> {
  const Failure(this.error);
  final AppFailure error;
}
