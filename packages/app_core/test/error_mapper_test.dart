import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapServerCodeToAppError', () {
    test('uses localized Chinese message for known code even when server message is English', () {
      final error = mapServerCodeToAppError(
        code: 40101,
        message: 'invalid password',
      );

      expect(error.type, AppErrorType.invalidCredentials);
      expect(error.message, '用户名或密码错误');
    });

    test('falls back to Chinese type message when unknown code has English server message', () {
      final error = mapServerCodeToAppError(
        code: 40999,
        message: 'resource conflict',
      );

      expect(error.type, AppErrorType.unknown);
      expect(error.message, '请求失败，请稍后重试');
    });

    test('keeps server message when it is already Chinese and code is unknown', () {
      final error = mapServerCodeToAppError(
        code: 40999,
        message: '自定义错误提示',
      );

      expect(error.type, AppErrorType.unknown);
      expect(error.message, '自定义错误提示');
    });

    test('normalizes generic internal error with Chinese localized message', () {
      final error = mapServerCodeToAppError(
        code: 50000,
        message: 'Exception: socket failed',
      );

      expect(error.type, AppErrorType.server);
      expect(error.message, '服务器内部错误');
    });
  });
}
