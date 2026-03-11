import 'package:app_core/app_core.dart';
import 'package:doctor/data/preference/app_prefs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

final class SessionStoreImpl implements SessionStore {
  SessionStoreImpl(FlutterSecureStorage secureStorage)
    : _delegate = SecurePrefSessionStore(
        keySet: _keySet,
        readSecureValue: (key) => secureStorage.read(key: key),
        writeSecureValue: (key, value) =>
            secureStorage.write(key: key, value: value),
        deleteSecureValue: (key) => secureStorage.delete(key: key),
        readPrincipalId: () => AppPrefs.sessionPrincipalId.value,
        writePrincipalId: AppPrefs.sessionPrincipalId.set,
        removePrincipalId: AppPrefs.sessionPrincipalId.remove,
        readAccessTokenExpiresAtMs: () => AppPrefs.accessTokenExpiresAtMs.value,
        writeAccessTokenExpiresAtMs: AppPrefs.accessTokenExpiresAtMs.set,
        removeAccessTokenExpiresAtMs: AppPrefs.accessTokenExpiresAtMs.remove,
        readRefreshTokenExpiresAtMs: () =>
            AppPrefs.refreshTokenExpiresAtMs.value,
        writeRefreshTokenExpiresAtMs: AppPrefs.refreshTokenExpiresAtMs.set,
        removeRefreshTokenExpiresAtMs: AppPrefs.refreshTokenExpiresAtMs.remove,
        getOrCreateDeviceId: () async {
          final existing = AppPrefs.deviceId.value;
          if (existing.isNotEmpty) return existing;

          final generated = const Uuid().v4();
          await AppPrefs.deviceId.set(generated);
          return generated;
        },
      );

  static const SessionStoreKeySet _keySet = SessionStoreKeySet(
    accessTokenKey: 'doctor_session_access_token',
    refreshTokenKey: 'doctor_session_refresh_token',
  );

  final SecurePrefSessionStore _delegate;

  @override
  Future<String> getOrCreateDeviceId() => _delegate.getOrCreateDeviceId();

  @override
  Future<Session?> readSession() => _delegate.readSession();

  @override
  Future<String?> readAccessToken() => _delegate.readAccessToken();

  @override
  Future<String?> readRefreshToken() => _delegate.readRefreshToken();

  @override
  Future<void> saveSession({
    required int principalId,
    required TokenPair tokenPair,
  }) {
    return _delegate.saveSession(
      principalId: principalId,
      tokenPair: tokenPair,
    );
  }

  @override
  Future<void> clearSession() => _delegate.clearSession();
}
