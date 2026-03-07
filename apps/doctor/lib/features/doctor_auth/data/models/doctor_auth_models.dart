import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';

final class DoctorAuthResponseDto {
  const DoctorAuthResponseDto({
    required this.doctorId,
    required this.tokenPair,
  });

  factory DoctorAuthResponseDto.fromJson(Map<String, dynamic> json) {
    final token = Map<String, dynamic>.from(json['token'] as Map? ?? const <String, dynamic>{});
    return DoctorAuthResponseDto(
      doctorId: (json['doctorId'] as num?)?.toInt() ?? 0,
      tokenPair: TokenPair(
        accessToken: token['accessToken'] as String? ?? '',
        refreshToken: token['refreshToken'] as String? ?? '',
        accessTokenExpiresInSeconds:
            (token['accessTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
        refreshTokenExpiresInSeconds:
            (token['refreshTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final int doctorId;
  final TokenPair tokenPair;

  DoctorAuthSession toDomain() {
    return DoctorAuthSession(doctorId: doctorId, tokenPair: tokenPair);
  }
}
