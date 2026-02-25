import 'dart:typed_data';

import 'package:mindisle_client/features/user/domain/entities/user_avatar.dart';
import 'package:mindisle_client/features/user/domain/entities/user_basic_profile.dart';
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

final class UpsertUserBasicProfileRequestDto {
  const UpsertUserBasicProfileRequestDto({
    this.fullName,
    this.gender,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.waistCm,
    this.diseaseHistory,
  });

  factory UpsertUserBasicProfileRequestDto.fromDomain(
    UpsertUserBasicProfilePayload payload,
  ) {
    return UpsertUserBasicProfileRequestDto(
      fullName: payload.fullName,
      gender: payload.gender,
      birthDate: payload.birthDate,
      heightCm: payload.heightCm,
      weightKg: payload.weightKg,
      waistCm: payload.waistCm,
      diseaseHistory: payload.diseaseHistory,
    );
  }

  final String? fullName;
  final UserGender? gender;
  final String? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? waistCm;
  final List<String>? diseaseHistory;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'gender': genderToWire(gender),
      'birthDate': birthDate,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'waistCm': waistCm,
      'diseaseHistory': diseaseHistory,
    };
  }
}

final class UserBasicProfileResponseDto {
  const UserBasicProfileResponseDto({
    required this.userId,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.waistCm,
    required this.diseaseHistory,
  });

  factory UserBasicProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return UserBasicProfileResponseDto(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String?,
      gender: genderFromWire(json['gender'] as String? ?? 'UNKNOWN'),
      birthDate: json['birthDate'] as String?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      diseaseHistory: _toStringList(json['diseaseHistory']),
    );
  }

  final int userId;
  final String? fullName;
  final UserGender gender;
  final String? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? waistCm;
  final List<String> diseaseHistory;

  UserBasicProfile toDomain() {
    return UserBasicProfile(
      userId: userId,
      fullName: fullName,
      gender: gender,
      birthDate: birthDate,
      heightCm: heightCm,
      weightKg: weightKg,
      waistCm: waistCm,
      diseaseHistory: diseaseHistory,
    );
  }
}

final class UserAvatarMetaResponseDto {
  const UserAvatarMetaResponseDto({
    required this.avatarUrl,
    required this.contentType,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.updatedAt,
  });

  factory UserAvatarMetaResponseDto.fromJson(Map<String, dynamic> json) {
    return UserAvatarMetaResponseDto(
      avatarUrl: json['avatarUrl'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'image/png',
      width: _toInt(json['width']),
      height: _toInt(json['height']),
      sizeBytes: _toInt(json['sizeBytes']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  final String avatarUrl;
  final String contentType;
  final int width;
  final int height;
  final int sizeBytes;
  final DateTime? updatedAt;

  UserAvatarMeta toDomain() {
    return UserAvatarMeta(
      avatarUrl: avatarUrl,
      contentType: contentType,
      width: width,
      height: height,
      sizeBytes: sizeBytes,
      updatedAt: updatedAt,
    );
  }
}

final class UserAvatarBinaryDto {
  const UserAvatarBinaryDto({
    required this.isNotModified,
    required this.bytes,
    required this.eTag,
    required this.lastModified,
    required this.cacheControl,
  });

  final bool isNotModified;
  final Uint8List? bytes;
  final String? eTag;
  final String? lastModified;
  final String? cacheControl;

  UserAvatarBinary toDomain() {
    if (isNotModified) {
      return UserAvatarBinary.notModified(
        eTag: eTag,
        lastModified: lastModified,
        cacheControl: cacheControl,
      );
    }

    return UserAvatarBinary(
      isNotModified: false,
      bytes: bytes,
      eTag: eTag,
      lastModified: lastModified,
      cacheControl: cacheControl,
    );
  }
}

List<String> _toStringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item.toString()).toList(growable: false);
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
