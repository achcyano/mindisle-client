import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/auth/domain/entities/auth_entities.dart';
import 'package:mindisle_client/features/auth/domain/repositories/auth_repository.dart';

final class SendSmsCodeUseCase {
  const SendSmsCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> execute({
    required String phone,
    required SmsPurpose purpose,
    String? forwardedFor,
  }) {
    return _repository.sendSmsCode(
      phone: phone,
      purpose: purpose,
      forwardedFor: forwardedFor,
    );
  }
}

final class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSessionResult>> execute({
    required String phone,
    required String smsCode,
    required String password,
    Map<String, dynamic>? profile,
  }) {
    return _repository.register(
      phone: phone,
      smsCode: smsCode,
      password: password,
      profile: profile,
    );
  }
}

final class LoginCheckUseCase {
  const LoginCheckUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<LoginCheckResult>> execute(String phone) {
    return _repository.loginCheck(phone: phone);
  }
}

final class LoginDirectUseCase {
  const LoginDirectUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSessionResult>> execute({
    required String phone,
    required String ticket,
  }) {
    return _repository.loginDirect(phone: phone, ticket: ticket);
  }
}

final class LoginPasswordUseCase {
  const LoginPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSessionResult>> execute({
    required String phone,
    required String password,
  }) {
    return _repository.loginPassword(phone: phone, password: password);
  }
}

final class RefreshTokenUseCase {
  const RefreshTokenUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSessionResult>> execute() {
    return _repository.refreshToken();
  }
}

final class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

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

final class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> execute({String? refreshToken}) {
    return _repository.logout(refreshToken: refreshToken);
  }
}
