import 'package:mindisle_client/data/preference/hive_pref_tool.dart';

abstract final class AppPrefs {
  // Whether the user has ever completed a successful login.
  static const hasCompletedFirstLogin = PrefVar<bool>(
    'has_completed_first_login',
    defaultValue: false,
  );

  static const deviceId = PrefVar<String>(
    'device_id',
    defaultValue: '',
  );

  static const sessionUserId = PrefVar<int>(
    'session_user_id',
    defaultValue: 0,
  );

  static const accessTokenExpiresAtMs = PrefVar<int>(
    'access_token_expires_at_ms',
    defaultValue: 0,
  );

  static const refreshTokenExpiresAtMs = PrefVar<int>(
    'refresh_token_expires_at_ms',
    defaultValue: 0,
  );

  static const themeMode = PrefVar<int>(
    'test_int',
    defaultValue: 0,
  );

  static const favoriteServerIds = PrefVar<List<String>>(
    'favorite_server_ids',
    defaultValue: <String>[],
    decode: _decodeStringList,
  );

  static const featureFlags = PrefVar<Map<String, dynamic>>(
    'feature_flags',
    defaultValue: <String, dynamic>{},
    decode: _decodeStringDynamicMap,
  );

  static const todayMoodEntry = PrefVar<Map<String, dynamic>>(
    'today_mood_entry',
    defaultValue: <String, dynamic>{},
    decode: _decodeStringDynamicMap,
  );
}

List<String> _decodeStringList(Object? raw) {
  if (raw is List) return raw.map((e) => e.toString()).toList();
  return const <String>[];
}

Map<String, dynamic> _decodeStringDynamicMap(Object? raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const <String, dynamic>{};
}
