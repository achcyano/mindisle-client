import 'package:mindisle_client/shared/session/session_models.dart';

abstract interface class SessionStore {
  Future<String> getOrCreateDeviceId();

  Future<Session?> readSession();

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> saveSession({
    required int userId,
    required TokenPair tokenPair,
  });

  Future<void> clearSession();
}
