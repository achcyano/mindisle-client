import 'package:app_core/app_core.dart';

abstract final class AppPrefs {
  static const deviceId = PrefVar<String>('doctor_device_id', defaultValue: '');
  static const hasSeenWelcome = PrefVar<bool>(
    'doctor_has_seen_welcome',
    defaultValue: false,
  );

  static const sessionPrincipalId = PrefVar<int>(
    'doctor_session_principal_id',
    defaultValue: 0,
  );

  static const accessTokenExpiresAtMs = PrefVar<int>(
    'doctor_access_token_expires_at_ms',
    defaultValue: 0,
  );

  static const refreshTokenExpiresAtMs = PrefVar<int>(
    'doctor_refresh_token_expires_at_ms',
    defaultValue: 0,
  );
}
