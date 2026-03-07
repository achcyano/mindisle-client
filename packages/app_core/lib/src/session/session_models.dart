final class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;
}

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
