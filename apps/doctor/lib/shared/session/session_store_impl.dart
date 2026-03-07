import 'package:app_core/app_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:doctor/data/preference/app_prefs.dart';
import 'package:uuid/uuid.dart';

final class SessionStoreImpl implements SessionStore {
  SessionStoreImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid = const Uuid();

  static const _accessTokenKey = 'doctor_session_access_token';
  static const _refreshTokenKey = 'doctor_session_refresh_token';

  @override
  Future<String> getOrCreateDeviceId() async {
    final existing = AppPrefs.deviceId.value;
    if (existing.isNotEmpty) return existing;

    final generated = _uuid.v4();
    await AppPrefs.deviceId.set(generated);
    return generated;
  }

  @override
  Future<Session?> readSession() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;

    final principalId = AppPrefs.sessionPrincipalId.value;
    if (principalId <= 0) return null;

    return Session(
      principalId: principalId,
      deviceId: await getOrCreateDeviceId(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAtMs: AppPrefs.accessTokenExpiresAtMs.value,
      refreshTokenExpiresAtMs: AppPrefs.refreshTokenExpiresAtMs.value,
    );
  }

  @override
  Future<String?> readAccessToken() => _secureStorage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _secureStorage.read(key: _refreshTokenKey);

  @override
  Future<void> saveSession({
    required int principalId,
    required TokenPair tokenPair,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final accessExpiresAt = nowMs + tokenPair.accessTokenExpiresInSeconds * 1000;
    final refreshExpiresAt = nowMs + tokenPair.refreshTokenExpiresInSeconds * 1000;

    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: tokenPair.accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: tokenPair.refreshToken),
      AppPrefs.sessionPrincipalId.set(principalId),
      AppPrefs.accessTokenExpiresAtMs.set(accessExpiresAt),
      AppPrefs.refreshTokenExpiresAtMs.set(refreshExpiresAt),
    ]);
  }

  @override
  Future<void> clearSession() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      AppPrefs.sessionPrincipalId.remove(),
      AppPrefs.accessTokenExpiresAtMs.remove(),
      AppPrefs.refreshTokenExpiresAtMs.remove(),
    ]);
  }
}
