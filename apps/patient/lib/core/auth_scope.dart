import 'package:app_core/app_core.dart';

const patientAuthScopeConfig = AuthScopeConfig(
  authPathPrefix: '/api/v1/auth',
  principalIdResponseKey: 'userId',
  supportsChangePassword: false,
  expiredMessage: '登录状态已过期，请重新登录',
);
