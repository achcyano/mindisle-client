enum UserGender {
  unknown,
  male,
  female,
  other,
}

final class UserProfile {
  const UserProfile({
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

  final int userId;
  final String phone;
  final String? fullName;
  final UserGender gender;
  final String? birthDate;
  final double? weightKg;
  final List<String> familyHistory;
  final List<String> medicalHistory;
  final List<String> medicationHistory;
}

final class UpsertUserProfilePayload {
  const UpsertUserProfilePayload({
    this.fullName,
    this.gender,
    this.birthDate,
    this.weightKg,
    this.familyHistory,
    this.medicalHistory,
    this.medicationHistory,
  });

  final String? fullName;
  final UserGender? gender;
  final String? birthDate;
  final double? weightKg;
  final List<String>? familyHistory;
  final List<String>? medicalHistory;
  final List<String>? medicationHistory;
}
