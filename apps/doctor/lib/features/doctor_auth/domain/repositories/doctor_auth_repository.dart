import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:app_core/app_core.dart';

abstract interface class DoctorAuthRepository {
  Future<Result<void>> sendSmsCode({
    required String phone,
    required DoctorSmsPurpose purpose,
  });

  Future<Result<DoctorAuthSession>> register({
    required String phone,
    required String smsCode,
    required String password,
    required String fullName,
    String? title,
    String? hospital,
  });

  Future<Result<DoctorAuthSession>> loginPassword({
    required String phone,
    required String password,
  });

  Future<Result<DoctorAuthSession>> refreshToken();

  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  });

  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<Result<void>> logout({String? refreshToken});
}
