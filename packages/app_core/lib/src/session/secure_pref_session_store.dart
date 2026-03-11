import 'package:app_core/src/session/session_models.dart';
import 'package:app_core/src/session/session_store.dart';
import 'package:app_core/src/session/session_store_persistence.dart';

typedef ReadIntPref = int Function();
typedef WriteIntPref = Future<void> Function(int value);
typedef RemovePref = Future<void> Function();
typedef ReadSecureValue = Future<String?> Function(String key);
typedef WriteSecureValue = Future<void> Function(String key, String value);
typedef DeleteSecureValue = Future<void> Function(String key);

class SecurePrefSessionStore implements SessionStore {
  SecurePrefSessionStore({
    required this.keySet,
    required this.readSecureValue,
    required this.writeSecureValue,
    required this.deleteSecureValue,
    required this.readPrincipalId,
    required this.writePrincipalId,
    required this.removePrincipalId,
    required this.readAccessTokenExpiresAtMs,
    required this.writeAccessTokenExpiresAtMs,
    required this.removeAccessTokenExpiresAtMs,
    required this.readRefreshTokenExpiresAtMs,
    required this.writeRefreshTokenExpiresAtMs,
    required this.removeRefreshTokenExpiresAtMs,
    required Future<String> Function() getOrCreateDeviceId,
  }) : _getOrCreateDeviceId = getOrCreateDeviceId;

  final SessionStoreKeySet keySet;
  final ReadSecureValue readSecureValue;
  final WriteSecureValue writeSecureValue;
  final DeleteSecureValue deleteSecureValue;
  final ReadIntPref readPrincipalId;
  final WriteIntPref writePrincipalId;
  final RemovePref removePrincipalId;
  final ReadIntPref readAccessTokenExpiresAtMs;
  final WriteIntPref writeAccessTokenExpiresAtMs;
  final RemovePref removeAccessTokenExpiresAtMs;
  final ReadIntPref readRefreshTokenExpiresAtMs;
  final WriteIntPref writeRefreshTokenExpiresAtMs;
  final RemovePref removeRefreshTokenExpiresAtMs;
  final Future<String> Function() _getOrCreateDeviceId;

  @override
  Future<String> getOrCreateDeviceId() => _getOrCreateDeviceId();

  @override
  Future<Session?> readSession() {
    return SessionStorePersistence.readSession(
      keySet: keySet,
      readSecureValue: readSecureValue,
      readPrincipalId: readPrincipalId,
      getOrCreateDeviceId: getOrCreateDeviceId,
      readAccessTokenExpiresAtMs: readAccessTokenExpiresAtMs,
      readRefreshTokenExpiresAtMs: readRefreshTokenExpiresAtMs,
    );
  }

  @override
  Future<String?> readAccessToken() {
    return SessionStorePersistence.readAccessToken(
      keySet: keySet,
      readSecureValue: readSecureValue,
    );
  }

  @override
  Future<String?> readRefreshToken() {
    return SessionStorePersistence.readRefreshToken(
      keySet: keySet,
      readSecureValue: readSecureValue,
    );
  }

  @override
  Future<void> saveSession({
    required int principalId,
    required TokenPair tokenPair,
  }) {
    return SessionStorePersistence.saveSession(
      keySet: keySet,
      principalId: principalId,
      tokenPair: tokenPair,
      writeSecureValue: writeSecureValue,
      writePrincipalId: writePrincipalId,
      writeAccessTokenExpiresAtMs: writeAccessTokenExpiresAtMs,
      writeRefreshTokenExpiresAtMs: writeRefreshTokenExpiresAtMs,
    );
  }

  @override
  Future<void> clearSession() {
    return SessionStorePersistence.clearSession(
      keySet: keySet,
      deleteSecureValue: deleteSecureValue,
      removePrincipalId: removePrincipalId,
      removeAccessTokenExpiresAtMs: removeAccessTokenExpiresAtMs,
      removeRefreshTokenExpiresAtMs: removeRefreshTokenExpiresAtMs,
    );
  }
}
