sealed class AppError implements Exception {
  const AppError();
  String get userMessage;
}

class NetworkError extends AppError {
  final String message;
  const NetworkError(this.message);
  @override String get userMessage => message;
}

class TimeoutError extends AppError {
  const TimeoutError();
  @override String get userMessage => 'Request timed out. Check your connection and retry.';
}

class RateLimitError extends AppError {
  final int retryAfterSeconds;
  const RateLimitError(this.retryAfterSeconds);
  @override String get userMessage => 'Too many requests. Please wait $retryAfterSeconds seconds.';
}

class NotFoundError extends AppError {
  const NotFoundError();
  @override String get userMessage => 'Not found. The item may not exist in this database.';
}

class ParseError extends AppError {
  final String message;
  const ParseError(this.message);
  @override String get userMessage => message;
}

class ValidationError extends AppError {
  final String message;
  const ValidationError(this.message);
  @override String get userMessage => message;
}
