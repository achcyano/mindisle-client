import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';

abstract interface class DoctorAuthRepository {
  Future<Result<void>> sendSmsCode({
    required String phone,
    required DoctorSmsPurpose purpose,
  });

  Future<Result<DoctorAuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
  });

  Future<Result<DoctorLoginCheckResult>> loginCheck({required String phone});

  Future<Result<DoctorAuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  });

  Future<Result<DoctorAuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  });

  Future<Result<DoctorAuthSessionResult>> refreshToken();

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
