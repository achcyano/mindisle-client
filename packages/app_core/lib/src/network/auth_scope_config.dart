import 'package:app_core/src/network/network_auth_strategy.dart';

final class AuthScopeConfig {
  const AuthScopeConfig({
    required this.authPathPrefix,
    required this.principalIdResponseKey,
    required this.supportsChangePassword,
    this.unauthorizedBusinessCode = 40100,
    this.expiredMessage = '登录状态已过期，请重新登录',
    this.deviceIdAttachRule,
  });

  final String authPathPrefix;
  final String principalIdResponseKey;
  final bool supportsChangePassword;
  final int unauthorizedBusinessCode;
  final String expiredMessage;
  final DeviceIdAttachRule? deviceIdAttachRule;

  String get normalizedAuthPathPrefix {
    final withLeadingSlash = authPathPrefix.startsWith('/')
        ? authPathPrefix
        : '/$authPathPrefix';
    return withLeadingSlash.endsWith('/')
        ? withLeadingSlash.substring(0, withLeadingSlash.length - 1)
        : withLeadingSlash;
  }

  String endpoint(String suffix) => '$normalizedAuthPathPrefix/$suffix';

  String get smsCodesPath => endpoint('sms-codes');
  String get registerPath => endpoint('register');
  String get loginCheckPath => endpoint('login/check');
  String get loginDirectPath => endpoint('login/direct');
  String get loginPasswordPath => endpoint('login/password');
  String get refreshPath => endpoint('token/refresh');
  String get resetPasswordPath => endpoint('password/reset');
  String get changePasswordPath => endpoint('password/change');
  String get logoutPath => endpoint('logout');

  Set<String> get publicPaths => <String>{
    smsCodesPath,
    registerPath,
    loginCheckPath,
    loginDirectPath,
    loginPasswordPath,
    refreshPath,
    resetPasswordPath,
  };

  NetworkAuthStrategy toNetworkAuthStrategy() {
    return NetworkAuthStrategy(
      authPathPrefix: '$normalizedAuthPathPrefix/',
      publicPaths: publicPaths,
      refreshPath: refreshPath,
      unauthorizedBusinessCode: unauthorizedBusinessCode,
      principalIdKeys: <String>[principalIdResponseKey],
      expiredMessage: expiredMessage,
      deviceIdAttachRule: deviceIdAttachRule,
    );
  }
}
