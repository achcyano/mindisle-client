import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/auth/domain/entities/auth_entities.dart';

abstract interface class AuthRepository {
  Future<Result<void>> sendSmsCode({
    required String phone,
    required SmsPurpose purpose,
    String? forwardedFor,
  });

  Future<Result<AuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
    Map<String, dynamic>? profile,
  });

  Future<Result<LoginCheckResult>> loginCheck({
    required String phone,
  });

  Future<Result<AuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  });

  Future<Result<AuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  });

  Future<Result<AuthSessionResult>> refreshToken();

  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  });

  Future<Result<void>> logout({String? refreshToken});
}
