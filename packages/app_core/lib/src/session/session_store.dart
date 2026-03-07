import 'package:app_core/src/session/session_models.dart';

abstract interface class SessionStore {
  Future<String> getOrCreateDeviceId();

  Future<Session?> readSession();

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> saveSession({
    required int principalId,
    required TokenPair tokenPair,
  });

  Future<void> clearSession();
}
