enum AppErrorType {
  validation,
  unauthorized,
  invalidCredentials,
  notFound,
  conflict,
  rateLimited,
  server,
  network,
  unknown,
}

final class AppError {
  const AppError({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
  });

  final AppErrorType type;
  final String message;
  final int? code;
  final int? statusCode;
}
