import 'package:app_core/app_core.dart';

const doctorAuthScopeConfig = AuthScopeConfig(
  authPathPrefix: '/api/v1/doctor/auth',
  principalIdResponseKey: 'doctorId',
  supportsChangePassword: true,
);
