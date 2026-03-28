import 'package:flutter_test/flutter_test.dart';
import 'package:patient/features/user/domain/entities/user_basic_profile.dart';
import 'package:patient/features/user/domain/entities/user_profile.dart';
import 'package:patient/features/user/presentation/profile/profile_completion_guard.dart';

void main() {
  group('basicProfileIncompleteReason', () {
    test('returns null for complete adult profile', () {
      final profile = _buildProfile(birthDate: '1990-03-20');
      expect(basicProfileIncompleteReason(profile), isNull);
      expect(isBasicProfileComplete(profile), isTrue);
    });

    test('returns underage reason when user is younger than 18', () {
      final profile = _buildProfile(birthDate: '2010-03-20');
      expect(basicProfileIncompleteReason(profile), '仅支持成年用户');
      expect(isBasicProfileComplete(profile), isFalse);
    });
  });
}

UserBasicProfile _buildProfile({required String birthDate}) {
  return UserBasicProfile(
    userId: 1,
    fullName: '测试用户',
    gender: UserGender.female,
    birthDate: birthDate,
    heightCm: 165,
    weightKg: 55,
    waistCm: 70,
    usesTcm: false,
    diseaseHistory: const <String>[],
  );
}
