import 'package:dio/dio.dart';
import 'package:app_core/src/result/app_error.dart';

AppError mapDioExceptionToAppError(DioException exception) {
  final response = exception.response;
  final data = response?.data;

  if (data is Map<String, dynamic> || data is Map) {
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
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
      message: '网络连接异常，请检查网络后重试',
    );
  }

  if (exception.type == DioExceptionType.badCertificate) {
    return const AppError(type: AppErrorType.network, message: '证书校验失败');
  }

  if (exception.type == DioExceptionType.badResponse) {
    final statusCode = response?.statusCode;
    final message = switch (statusCode) {
      400 => '请求参数错误',
      401 => '登录状态已过期，请重新登录',
      403 => '无权限访问',
      404 => '请求的资源不存在',
      409 => '请求冲突，请稍后再试',
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
  final serverMessage = message.trim();
  final type = switch (code) {
    40000 ||
    40001 ||
    40002 ||
    40003 ||
    40004 ||
    40010 ||
    40011 ||
    40020 ||
    40021 ||
    40030 ||
    40040 ||
    40041 => AppErrorType.validation,
    40042 || 40101 => AppErrorType.invalidCredentials,
    40100 || 40310 || 40320 || 40340 => AppErrorType.unauthorized,
    40401 ||
    40402 ||
    40403 ||
    40410 ||
    40411 ||
    40420 ||
    40421 ||
    40422 ||
    40430 ||
    40440 ||
    40441 => AppErrorType.notFound,
    40901 || 40910 || 40911 || 40920 || 40921 || 40940 => AppErrorType.conflict,
    42901 || 42902 || 42903 || 42910 || 42920 => AppErrorType.rateLimited,
    42220 => AppErrorType.validation,
    50000 ||
    50010 ||
    50020 ||
    50021 ||
    50030 ||
    50201 ||
    50202 => AppErrorType.server,
    _ => AppErrorType.unknown,
  };

  final localizedMessage = _localizedMessageForCode(code, serverMessage);
  final resolvedMessage = _resolveAppErrorMessage(
    type: type,
    serverMessage: serverMessage,
    localizedMessage: localizedMessage,
  );

  return AppError(
    type: type,
    message: resolvedMessage,
    code: code,
    statusCode: statusCode,
  );
}

String _resolveAppErrorMessage({
  required AppErrorType type,
  required String serverMessage,
  required String? localizedMessage,
}) {
  if (localizedMessage != null) return localizedMessage;
  if (_containsCjk(serverMessage)) return serverMessage;
  return _fallbackMessageForType(type);
}

bool _containsCjk(String text) {
  if (text.isEmpty) return false;
  return RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]').hasMatch(text);
}

String? _localizedMessageForCode(int code, String serverMessage) {
  return switch (code) {
    0 => '成功',
    40000 => '请求参数错误',
    40001 => '手机号格式错误',
    40002 => '密码长度不能小于 6 位',
    40003 => '短信验证码错误',
    40004 => '短信验证码已过期',
    40010 => 'AI 请求内容不能为空',
    40011 => '请求消息不能为空',
    40020 => '量表提交参数错误',
    40021 => '量表作答数据错误',
    40030 => '医生绑定参数错误',
    40040 => '医生端注册参数错误',
    40041 => '医生端认证参数错误',
    40042 => '医生端密码错误',
    40100 => '登录状态已过期，请重新登录',
    40101 => '用户名或密码错误',
    40310 => '无权限访问该资源',
    40320 => '不允许绑定该医生',
    40340 => '无权限访问该医生资源',
    40401 => '用户不存在',
    40402 => '医生不存在',
    40403 => '量表不存在',
    40410 => '会话不存在',
    40411 => '量表记录不存在',
    40420 => '用药记录不存在',
    40421 => '用药计划不存在',
    40422 => '副作用记录不存在',
    40430 => '绑定记录不存在',
    40440 => '医生不存在',
    40441 => '医生绑定历史不存在',
    40901 => '手机号已注册',
    40910 => '量表会话状态冲突',
    40911 => '量表会话已结束或不可提交',
    40920 => '用药计划冲突',
    40921 => '用药计划时间冲突',
    40940 => '绑定码已失效',
    42220 => '量表答案校验失败',
    42901 => '请求过于频繁',
    42902 => '短信发送过于频繁',
    42903 => '短信验证码校验过于频繁',
    42910 => 'AI 请求过于频繁',
    42920 => '量表提交过于频繁',
    50010 when _isSmsValidateFailure(serverMessage) => '短信验证码校验失败',
    50010 => '短信服务暂时不可用',
    50020 => 'AI 服务暂时不可用',
    50021 => 'AI 响应解析失败',
    50030 => '第三方服务暂时不可用',
    50201 => '数据库服务暂时不可用',
    50202 => '缓存服务暂时不可用',
    50000 => '服务器内部错误',
    _ => null,
  };
}

bool _isSmsValidateFailure(String serverMessage) {
  if (serverMessage.isEmpty) return false;
  final raw = serverMessage.toLowerCase();
  return raw.contains('validatefail') || raw.contains('校验');
}

String _fallbackMessageForType(AppErrorType type) {
  return switch (type) {
    AppErrorType.validation => '请求参数错误',
    AppErrorType.unauthorized => '登录状态已过期，请重新登录',
    AppErrorType.invalidCredentials => '用户名或密码错误',
    AppErrorType.notFound => '请求的资源不存在',
    AppErrorType.conflict => '请求冲突，请稍后再试',
    AppErrorType.rateLimited => '请求过于频繁，请稍后再试',
    AppErrorType.server => '服务器开小差了，请稍后重试',
    AppErrorType.network => '网络连接异常，请检查网络后重试',
    AppErrorType.unknown => '请求失败，请稍后重试',
  };
}
