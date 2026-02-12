import 'package:mindisle_client/features/auth/domain/entities/auth_entities.dart';
import 'package:mindisle_client/shared/session/session_models.dart';

String smsPurposeToWire(SmsPurpose purpose) {
  return switch (purpose) {
    SmsPurpose.register => 'REGISTER',
    SmsPurpose.resetPassword => 'RESET_PASSWORD',
  };
}

AuthLoginDecision loginDecisionFromWire(String raw) {
  return switch (raw) {
    'REGISTER_REQUIRED' => AuthLoginDecision.registerRequired,
    'DIRECT_LOGIN_ALLOWED' => AuthLoginDecision.directLoginAllowed,
    'PASSWORD_REQUIRED' => AuthLoginDecision.passwordRequired,
    _ => AuthLoginDecision.passwordRequired,
  };
}

final class SendSmsCodeRequest {
  const SendSmsCodeRequest({
    required this.phone,
    required this.purpose,
  });

  final String phone;
  final SmsPurpose purpose;

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'purpose': smsPurposeToWire(purpose),
    };
  }
}

final class RegisterRequest {
  const RegisterRequest({
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
      'profile': profile,
    };
  }
}

final class LoginCheckRequest {
  const LoginCheckRequest({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() => {'phone': phone};
}

final class DirectLoginRequest {
  const DirectLoginRequest({
    required this.phone,
    required this.ticket,
  });

  final String phone;
  final String ticket;

  Map<String, dynamic> toJson() => {'phone': phone, 'ticket': ticket};
}

final class PasswordLoginRequest {
  const PasswordLoginRequest({
    required this.phone,
    required this.password,
  });

  final String phone;
  final String password;

  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}

final class TokenRefreshRequest {
  const TokenRefreshRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

final class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.phone,
    required this.smsCode,
    required this.newPassword,
  });

  final String phone;
  final String smsCode;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'smsCode': smsCode,
      'newPassword': newPassword,
    };
  }
}

final class LogoutRequest {
  const LogoutRequest({this.refreshToken});

  final String? refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
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

final class AuthResponseDto {
  const AuthResponseDto({
    required this.userId,
    required this.token,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      token: TokenPairDto.fromJson(Map<String, dynamic>.from(json['token'])),
    );
  }

  final int userId;
  final TokenPairDto token;

  AuthSessionResult toDomain() {
    return AuthSessionResult(userId: userId, tokenPair: token.toDomain());
  }
}

final class LoginCheckResponseDto {
  const LoginCheckResponseDto({
    required this.decision,
    this.ticket,
  });

  factory LoginCheckResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginCheckResponseDto(
      decision: loginDecisionFromWire(json['decision'] as String? ?? ''),
      ticket: json['ticket'] as String?,
    );
  }

  final AuthLoginDecision decision;
  final String? ticket;

  LoginCheckResult toDomain() {
    return LoginCheckResult(decision: decision, ticket: ticket);
  }
}
