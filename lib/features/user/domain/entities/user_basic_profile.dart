import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';

final class UserBasicProfile {
  const UserBasicProfile({
    required this.userId,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.waistCm,
    required this.diseaseHistory,
  });

  final int userId;
  final String? fullName;
  final UserGender gender;
  final String? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? waistCm;
  final List<String> diseaseHistory;
}

final class UpsertUserBasicProfilePayload {
  const UpsertUserBasicProfilePayload({
    this.fullName,
    this.gender,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.waistCm,
    this.diseaseHistory,
  });

  final String? fullName;
  final UserGender? gender;
  final String? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? waistCm;
  final List<String>? diseaseHistory;
}
