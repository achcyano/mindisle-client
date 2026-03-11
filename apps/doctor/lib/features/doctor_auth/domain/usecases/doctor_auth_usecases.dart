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

  Future<Result<DoctorAuthSessionResult>> execute({
    required String phone,
    required String smsCode,
    required String password,
  }) {
    return _repository.register(
      phone: phone,
      smsCode: smsCode,
      password: password,
    );
  }
}

final class DoctorLoginCheckUseCase {
  const DoctorLoginCheckUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<DoctorLoginCheckResult>> execute(String phone) {
    return _repository.loginCheck(phone: phone);
  }
}

final class DoctorLoginDirectUseCase {
  const DoctorLoginDirectUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<DoctorAuthSessionResult>> execute({
    required String phone,
    required String ticket,
  }) {
    return _repository.loginDirect(phone: phone, ticket: ticket);
  }
}

final class DoctorLoginPasswordUseCase {
  const DoctorLoginPasswordUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<DoctorAuthSessionResult>> execute({
    required String phone,
    required String password,
  }) {
    return _repository.loginPassword(phone: phone, password: password);
  }
}

final class DoctorRefreshTokenUseCase {
  const DoctorRefreshTokenUseCase(this._repository);

  final DoctorAuthRepository _repository;

  Future<Result<DoctorAuthSessionResult>> execute() {
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
