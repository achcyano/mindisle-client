enum AuthSmsPurpose { register, resetPassword }

String authSmsPurposeToWire(AuthSmsPurpose purpose) {
  return switch (purpose) {
    AuthSmsPurpose.register => 'REGISTER',
    AuthSmsPurpose.resetPassword => 'RESET_PASSWORD',
  };
}

enum AuthLoginDecision {
  registerRequired,
  directLoginAllowed,
  passwordRequired,
}

AuthLoginDecision authLoginDecisionFromWire(String raw) {
  return switch (raw) {
    'REGISTER_REQUIRED' => AuthLoginDecision.registerRequired,
    'DIRECT_LOGIN_ALLOWED' => AuthLoginDecision.directLoginAllowed,
    'PASSWORD_REQUIRED' => AuthLoginDecision.passwordRequired,
    _ => AuthLoginDecision.passwordRequired,
  };
}

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

final class AuthLoginCheckResult {
  const AuthLoginCheckResult({required this.decision, this.ticket});

  final AuthLoginDecision decision;
  final String? ticket;
}

final class PrincipalAuthSessionResult {
  const PrincipalAuthSessionResult({
    required this.principalId,
    required this.tokenPair,
  });

  final int principalId;
  final TokenPair tokenPair;
}

final class SendSmsCodePayload {
  const SendSmsCodePayload({required this.phone, required this.purpose});

  final String phone;
  final AuthSmsPurpose purpose;

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'purpose': authSmsPurposeToWire(purpose)};
  }
}

final class RegisterPayload {
  const RegisterPayload({
    required this.phone,
    required this.smsCode,
    required this.password,
    this.profile,
  });

  final String phone;
  final String smsCode;
  final String password;
  final Map<String, dynamic>? profile;

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'smsCode': smsCode,
      'password': password,
      if (profile != null) 'profile': profile,
    };
  }
}

final class LoginCheckPayload {
  const LoginCheckPayload({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() => {'phone': phone};
}

final class DirectLoginPayload {
  const DirectLoginPayload({required this.phone, required this.ticket});

  final String phone;
  final String ticket;

  Map<String, dynamic> toJson() => {'phone': phone, 'ticket': ticket};
}

final class PasswordLoginPayload {
  const PasswordLoginPayload({required this.phone, required this.password});

  final String phone;
  final String password;

  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}

final class TokenRefreshPayload {
  const TokenRefreshPayload({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

final class ResetPasswordPayload {
  const ResetPasswordPayload({
    required this.phone,
    required this.smsCode,
    required this.newPassword,
  });

  final String phone;
  final String smsCode;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'smsCode': smsCode, 'newPassword': newPassword};
  }
}

final class LogoutPayload {
  const LogoutPayload({this.refreshToken});

  final String? refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

final class ChangePasswordPayload {
  const ChangePasswordPayload({
    required this.oldPassword,
    required this.newPassword,
  });

  final String oldPassword;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'oldPassword': oldPassword, 'newPassword': newPassword};
  }
}

final class TokenPairDto {
  const TokenPairDto({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory TokenPairDto.fromJson(Map<String, dynamic> json) {
    return TokenPairDto(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresInSeconds:
          (json['accessTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
      refreshTokenExpiresInSeconds:
          (json['refreshTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;

  TokenPair toDomain() {
    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresInSeconds: accessTokenExpiresInSeconds,
      refreshTokenExpiresInSeconds: refreshTokenExpiresInSeconds,
    );
  }
}

final class AuthSessionResponseDto {
  const AuthSessionResponseDto({
    required this.principalId,
    required this.token,
  });

  factory AuthSessionResponseDto.fromJson(
    Map<String, dynamic> json, {
    required String principalIdKey,
  }) {
    return AuthSessionResponseDto(
      principalId: (json[principalIdKey] as num?)?.toInt() ?? 0,
      token: TokenPairDto.fromJson(
        Map<String, dynamic>.from(
          json['token'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  final int principalId;
  final TokenPairDto token;

  PrincipalAuthSessionResult toDomain() {
    return PrincipalAuthSessionResult(
      principalId: principalId,
      tokenPair: token.toDomain(),
    );
  }
}

final class AuthLoginCheckResponseDto {
  const AuthLoginCheckResponseDto({required this.decision, this.ticket});

  factory AuthLoginCheckResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthLoginCheckResponseDto(
      decision: authLoginDecisionFromWire(json['decision'] as String? ?? ''),
      ticket: json['ticket'] as String?,
    );
  }

  final AuthLoginDecision decision;
  final String? ticket;

  AuthLoginCheckResult toDomain() {
    return AuthLoginCheckResult(decision: decision, ticket: ticket);
  }
}
