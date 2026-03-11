export 'package:models/models.dart' show TokenPair;

final class Session {
  const Session({
    required this.principalId,
    required this.deviceId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAtMs,
    required this.refreshTokenExpiresAtMs,
  });

  final int principalId;
  final String deviceId;
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresAtMs;
  final int refreshTokenExpiresAtMs;
}
