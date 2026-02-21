import 'package:dio/dio.dart';
import 'package:mindisle_client/core/result/app_error.dart';

AppError mapDioExceptionToAppError(DioException exception) {
  final response = exception.response;
  final data = response?.data;

  if (data is Map<String, dynamic> || data is Map) {
    final map = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
    final code = (map['code'] as num?)?.toInt();
    final message = (map['message'] as String?) ?? '';
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
      message: '网络连接失败，请检查网络后重试',
    );
  }

  if (exception.type == DioExceptionType.badCertificate) {
    return const AppError(
      type: AppErrorType.network,
      message: '网络证书校验失败',
    );
  }

  if (exception.type == DioExceptionType.badResponse) {
    final statusCode = response?.statusCode;
    final message = switch (statusCode) {
      400 => '请求参数不合法',
      401 => '登录状态已失效，请重新登录',
      403 => '无权访问该资源',
      404 => '请求资源不存在',
      409 => '请求冲突，请稍后重试',
      429 => '请求过于频繁，请稍后再试',
      int code when code >= 500 => '服务器开小差了，请稍后重试',
      _ => '请求失败，请稍后重试',
    };

    return AppError(
      type: statusCode != null && statusCode >= 500
          ? AppErrorType.server
          : AppErrorType.unknown,
      message: message,
      statusCode: statusCode,
    );
  }

  return AppError(
    type: AppErrorType.unknown,
    message: '请求失败，请稍后重试',
    statusCode: response?.statusCode,
  );
}

AppError mapServerCodeToAppError({
  required int code,
  required String message,
  int? statusCode,
}) {
  final type = switch (code) {
    40000 || 40001 || 40002 || 40003 || 40004 || 40010 || 40011 =>
      AppErrorType.validation,
    40100 || 40310 => AppErrorType.unauthorized,
    40101 => AppErrorType.invalidCredentials,
    40401 || 40402 || 40410 || 40411 => AppErrorType.notFound,
    40901 || 40910 || 40911 => AppErrorType.conflict,
    42901 || 42902 || 42903 || 42910 => AppErrorType.rateLimited,
    50000 || 50010 || 50020 || 50021 || 50201 || 50202 => AppErrorType.server,
    _ => AppErrorType.unknown,
  };

  final localizedMessage =
      _localizedMessageForCode(code, message) ?? _fallbackMessageForType(type);

  return AppError(
    type: type,
    message: localizedMessage,
    code: code,
    statusCode: statusCode,
  );
}

String? _localizedMessageForCode(int code, String serverMessage) {
  return switch (code) {
    0 => '成功',
    40000 => '请求参数不合法',
    40001 => '手机号格式不正确',
    40002 => '密码长度不能少于 6 位',
    40003 => '验证码错误或已过期',
    40004 => '登录票据无效或已过期',
    40010 => 'AI 请求参数不合法',
    40011 => '选项结构非法',
    40100 => '登录状态已失效，请重新登录',
    40101 => '账号或密码错误',
    40310 => '无权访问该会话或生成任务',
    40401 => '该手机号尚未注册',
    40402 => '该手机号未注册',
    40410 => '会话不存在',
    40411 => '生成任务不存在',
    40901 => '该手机号已被注册',
    40910 => '请求冲突，请稍后重试',
    40911 => '重连窗口已过期，请重新发起提问',
    42901 => '操作过于频繁，请稍后再试',
    42902 => '今日短信次数已达上限',
    42903 => '验证码尝试次数过多，请稍后再试',
    42910 => '请求过于频繁，请稍后重试',
    50010 when _isSmsValidateFailure(serverMessage) => '验证码错误或已过期',
    50010 => '短信服务暂不可用，请稍后重试',
    50020 => 'AI 服务暂不可用，请稍后重试',
    50021 => '回复解析失败，请稍后重试',
    50201 => '上游服务暂不可用，请稍后重试',
    50202 => '选项生成失败，请稍后重试',
    50000 => '服务暂不可用，请稍后重试',
    _ => null,
  };
}

bool _isSmsValidateFailure(String serverMessage) {
  if (serverMessage.isEmpty) return false;
  final raw = serverMessage.toLowerCase();
  return raw.contains('validatefail') || raw.contains('验证失败');
}

String _fallbackMessageForType(AppErrorType type) {
  return switch (type) {
    AppErrorType.validation => '请求参数不合法',
    AppErrorType.unauthorized => '登录状态已失效，请重新登录',
    AppErrorType.invalidCredentials => '账号或密码错误',
    AppErrorType.notFound => '请求资源不存在',
    AppErrorType.conflict => '请求冲突，请稍后重试',
    AppErrorType.rateLimited => '请求过于频繁，请稍后再试',
    AppErrorType.server => '服务暂不可用，请稍后重试',
    AppErrorType.network => '网络连接失败，请检查网络后重试',
    AppErrorType.unknown => '请求失败，请稍后重试',
  };
}
