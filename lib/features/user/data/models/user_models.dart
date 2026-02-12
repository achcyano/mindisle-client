import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';

String? genderToWire(UserGender? gender) {
  if (gender == null) return null;
  return switch (gender) {
    UserGender.unknown => 'UNKNOWN',
    UserGender.male => 'MALE',
    UserGender.female => 'FEMALE',
    UserGender.other => 'OTHER',
  };
}

UserGender genderFromWire(String raw) {
  return switch (raw) {
    'MALE' => UserGender.male,
    'FEMALE' => UserGender.female,
    'OTHER' => UserGender.other,
    _ => UserGender.unknown,
  };
}

final class UpsertUserProfileRequestDto {
  const UpsertUserProfileRequestDto({
    this.fullName,
    this.gender,
    this.birthDate,
    this.weightKg,
    this.familyHistory,
    this.medicalHistory,
    this.medicationHistory,
  });

  factory UpsertUserProfileRequestDto.fromDomain(UpsertUserProfilePayload payload) {
    return UpsertUserProfileRequestDto(
      fullName: payload.fullName,
      gender: payload.gender,
      birthDate: payload.birthDate,
      weightKg: payload.weightKg,
      familyHistory: payload.familyHistory,
      medicalHistory: payload.medicalHistory,
      medicationHistory: payload.medicationHistory,
    );
  }

  final String? fullName;
  final UserGender? gender;
  final String? birthDate;
  final double? weightKg;
  final List<String>? familyHistory;
  final List<String>? medicalHistory;
  final List<String>? medicationHistory;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'gender': genderToWire(gender),
      'birthDate': birthDate,
      'weightKg': weightKg,
      'familyHistory': familyHistory,
      'medicalHistory': medicalHistory,
      'medicationHistory': medicationHistory,
    };
  }
}

final class UserProfileResponseDto {
  const UserProfileResponseDto({
    required this.userId,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.weightKg,
    required this.familyHistory,
    required this.medicalHistory,
    required this.medicationHistory,
  });

  factory UserProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseDto(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      fullName: json['fullName'] as String?,
      gender: genderFromWire(json['gender'] as String? ?? 'UNKNOWN'),
      birthDate: json['birthDate'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      familyHistory: _toStringList(json['familyHistory']),
      medicalHistory: _toStringList(json['medicalHistory']),
      medicationHistory: _toStringList(json['medicationHistory']),
    );
  }

  final int userId;
  final String phone;
  final String? fullName;
  final UserGender gender;
  final String? birthDate;
  final double? weightKg;
  final List<String> familyHistory;
  final List<String> medicalHistory;
  final List<String> medicationHistory;

  UserProfile toDomain() {
    return UserProfile(
      userId: userId,
      phone: phone,
      fullName: fullName,
      gender: gender,
      birthDate: birthDate,
      weightKg: weightKg,
      familyHistory: familyHistory,
      medicalHistory: medicalHistory,
      medicationHistory: medicationHistory,
    );
  }
}

List<String> _toStringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item.toString()).toList(growable: false);
}
