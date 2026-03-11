import 'package:app_core/src/session/session_models.dart';

final class SessionStoreKeySet {
  const SessionStoreKeySet({
    required this.accessTokenKey,
    required this.refreshTokenKey,
  });

  final String accessTokenKey;
  final String refreshTokenKey;
}

final class SessionStorePersistence {
  const SessionStorePersistence._();

  static Future<Session?> readSession({
    required SessionStoreKeySet keySet,
    required Future<String?> Function(String key) readSecureValue,
    required int Function() readPrincipalId,
    required Future<String> Function() getOrCreateDeviceId,
    required int Function() readAccessTokenExpiresAtMs,
    required int Function() readRefreshTokenExpiresAtMs,
  }) async {
    final accessToken = await readSecureValue(keySet.accessTokenKey);
    final refreshToken = await readSecureValue(keySet.refreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;

    final principalId = readPrincipalId();
    if (principalId <= 0) return null;

    return Session(
      principalId: principalId,
      deviceId: await getOrCreateDeviceId(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAtMs: readAccessTokenExpiresAtMs(),
      refreshTokenExpiresAtMs: readRefreshTokenExpiresAtMs(),
    );
  }

  static Future<String?> readAccessToken({
    required SessionStoreKeySet keySet,
    required Future<String?> Function(String key) readSecureValue,
  }) {
    return readSecureValue(keySet.accessTokenKey);
  }

  static Future<String?> readRefreshToken({
    required SessionStoreKeySet keySet,
    required Future<String?> Function(String key) readSecureValue,
  }) {
    return readSecureValue(keySet.refreshTokenKey);
  }

  static Future<void> saveSession({
    required SessionStoreKeySet keySet,
    required int principalId,
    required TokenPair tokenPair,
    required Future<void> Function(String key, String value) writeSecureValue,
    required Future<void> Function(int value) writePrincipalId,
    required Future<void> Function(int value) writeAccessTokenExpiresAtMs,
    required Future<void> Function(int value) writeRefreshTokenExpiresAtMs,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final accessExpiresAt =
        nowMs + tokenPair.accessTokenExpiresInSeconds * 1000;
    final refreshExpiresAt =
        nowMs + tokenPair.refreshTokenExpiresInSeconds * 1000;

    await Future.wait(<Future<void>>[
      writeSecureValue(keySet.accessTokenKey, tokenPair.accessToken),
      writeSecureValue(keySet.refreshTokenKey, tokenPair.refreshToken),
      writePrincipalId(principalId),
      writeAccessTokenExpiresAtMs(accessExpiresAt),
      writeRefreshTokenExpiresAtMs(refreshExpiresAt),
    ]);
  }

  static Future<void> clearSession({
    required SessionStoreKeySet keySet,
    required Future<void> Function(String key) deleteSecureValue,
    required Future<void> Function() removePrincipalId,
    required Future<void> Function() removeAccessTokenExpiresAtMs,
    required Future<void> Function() removeRefreshTokenExpiresAtMs,
  }) async {
    await Future.wait(<Future<void>>[
      deleteSecureValue(keySet.accessTokenKey),
      deleteSecureValue(keySet.refreshTokenKey),
      removePrincipalId(),
      removeAccessTokenExpiresAtMs(),
      removeRefreshTokenExpiresAtMs(),
    ]);
  }
}
