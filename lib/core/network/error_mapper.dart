import 'package:dio/dio.dart';
import 'package:mindisle_client/core/result/app_error.dart';

AppError mapDioExceptionToAppError(DioException exception) {
  final response = exception.response;
  final data = response?.data;

  if (data is Map<String, dynamic>) {
    final code = (data['code'] as num?)?.toInt();
    final message = (data['message'] as String?) ?? 'Server error';
    if (code != null) {
      return mapServerCodeToAppError(
        code: code,
        message: message,
        statusCode: response?.statusCode,
      );
    }
  }

  if (exception.type == DioExceptionType.connectionTimeout ||
      exception.type == DioExceptionType.receiveTimeout ||
      exception.type == DioExceptionType.sendTimeout ||
      exception.type == DioExceptionType.connectionError) {
    return const AppError(
      type: AppErrorType.network,
      message: 'Network connection failed',
    );
  }

  return AppError(
    type: AppErrorType.unknown,
    message: exception.message ?? 'Unknown request error',
    statusCode: response?.statusCode,
  );
}

AppError mapServerCodeToAppError({
  required int code,
  required String message,
  int? statusCode,
}) {
  final type = switch (code) {
    40000 || 40001 || 40002 || 40003 || 40004 => AppErrorType.validation,
    40100 => AppErrorType.unauthorized,
    40101 => AppErrorType.invalidCredentials,
    40401 || 40402 => AppErrorType.notFound,
    40901 => AppErrorType.conflict,
    42901 || 42902 || 42903 => AppErrorType.rateLimited,
    50000 || 50010 => AppErrorType.server,
    _ => AppErrorType.unknown,
  };

  return AppError(
    type: type,
    message: message,
    code: code,
    statusCode: statusCode,
  );
}
