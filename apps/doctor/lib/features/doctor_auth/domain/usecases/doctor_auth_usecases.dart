import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/domain/repositories/doctor_auth_repository.dart';

final class SendDoctorSmsCodeUseCase {
  const SendDoctorSmsCodeUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<void>> execute({
    required String phone,
    required DoctorSmsPurpose purpose,
  }) {
    return _repository.sendSmsCode(phone: phone, purpose: purpose);
  }
}

final class DoctorRegisterUseCase {
  const DoctorRegisterUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<DoctorAuthSession>> execute({
    required String phone,
    required String smsCode,
    required String password,
    required String fullName,
    String? title,
    String? hospital,
  }) {
    return _repository.register(
      phone: phone,
      smsCode: smsCode,
      password: password,
      fullName: fullName,
      title: title,
      hospital: hospital,
    );
  }
}

final class DoctorLoginPasswordUseCase {
  const DoctorLoginPasswordUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<DoctorAuthSession>> execute({
    required String phone,
    required String password,
  }) {
    return _repository.loginPassword(phone: phone, password: password);
  }
}

final class DoctorRefreshTokenUseCase {
  const DoctorRefreshTokenUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<DoctorAuthSession>> execute() {
    return _repository.refreshToken();
  }
}

final class DoctorResetPasswordUseCase {
  const DoctorResetPasswordUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<void>> execute({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      phone: phone,
      smsCode: smsCode,
      newPassword: newPassword,
    );
  }
}

final class DoctorChangePasswordUseCase {
  const DoctorChangePasswordUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<void>> execute({
    required String oldPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}

final class DoctorLogoutUseCase {
  const DoctorLogoutUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<void>> execute({String? refreshToken}) {
    return _repository.logout(refreshToken: refreshToken);
  }
}
