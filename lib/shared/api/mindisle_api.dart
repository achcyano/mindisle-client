import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/auth/domain/entities/auth_entities.dart';
import 'package:mindisle_client/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mindisle_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/domain/usecases/user_usecases.dart';
import 'package:mindisle_client/features/user/presentation/providers/user_providers.dart';

final mindIsleApiProvider = Provider<MindIsleApi>((ref) {
  return MindIsleApi(
    auth: MindIsleAuthApi(
      sendSmsCodeUseCase: ref.watch(sendSmsCodeUseCaseProvider),
      registerUseCase: ref.watch(registerUseCaseProvider),
      loginCheckUseCase: ref.watch(loginCheckUseCaseProvider),
      loginDirectUseCase: ref.watch(loginDirectUseCaseProvider),
      loginPasswordUseCase: ref.watch(loginPasswordUseCaseProvider),
      refreshTokenUseCase: ref.watch(refreshTokenUseCaseProvider),
      resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
      logoutUseCase: ref.watch(logoutUseCaseProvider),
    ),
    user: MindIsleUserApi(
      getMeUseCase: ref.watch(getMeUseCaseProvider),
      updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
    ),
  );
});

final class MindIsleApi {
  const MindIsleApi({
    required this.auth,
    required this.user,
  });

  final MindIsleAuthApi auth;
  final MindIsleUserApi user;
}

final class MindIsleAuthApi {
  const MindIsleAuthApi({
    required SendSmsCodeUseCase sendSmsCodeUseCase,
    required RegisterUseCase registerUseCase,
    required LoginCheckUseCase loginCheckUseCase,
    required LoginDirectUseCase loginDirectUseCase,
    required LoginPasswordUseCase loginPasswordUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _sendSmsCodeUseCase = sendSmsCodeUseCase,
        _registerUseCase = registerUseCase,
        _loginCheckUseCase = loginCheckUseCase,
        _loginDirectUseCase = loginDirectUseCase,
        _loginPasswordUseCase = loginPasswordUseCase,
        _refreshTokenUseCase = refreshTokenUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _logoutUseCase = logoutUseCase;

  final SendSmsCodeUseCase _sendSmsCodeUseCase;
  final RegisterUseCase _registerUseCase;
  final LoginCheckUseCase _loginCheckUseCase;
  final LoginDirectUseCase _loginDirectUseCase;
  final LoginPasswordUseCase _loginPasswordUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final LogoutUseCase _logoutUseCase;

  Future<Result<void>> sendSmsCode({
    required String phone,
    required SmsPurpose purpose,
    String? forwardedFor,
  }) {
    return _sendSmsCodeUseCase.execute(
      phone: phone,
      purpose: purpose,
      forwardedFor: forwardedFor,
    );
  }

  Future<Result<AuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
    Map<String, dynamic>? profile,
  }) {
    return _registerUseCase.execute(
      phone: phone,
      smsCode: smsCode,
      password: password,
      profile: profile,
    );
  }

  Future<Result<LoginCheckResult>> loginCheck(String phone) {
    return _loginCheckUseCase.execute(phone);
  }

  Future<Result<AuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  }) {
    return _loginDirectUseCase.execute(phone: phone, ticket: ticket);
  }

  Future<Result<AuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  }) {
    return _loginPasswordUseCase.execute(phone: phone, password: password);
  }

  Future<Result<AuthSessionResult>> refreshToken() {
    return _refreshTokenUseCase.execute();
  }

  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) {
    return _resetPasswordUseCase.execute(
      phone: phone,
      smsCode: smsCode,
      newPassword: newPassword,
    );
  }

  Future<Result<void>> logout({String? refreshToken}) {
    return _logoutUseCase.execute(refreshToken: refreshToken);
  }
}

final class MindIsleUserApi {
  const MindIsleUserApi({
    required GetMeUseCase getMeUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  })  : _getMeUseCase = getMeUseCase,
        _updateProfileUseCase = updateProfileUseCase;

  final GetMeUseCase _getMeUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  Future<Result<UserProfile>> getMe() {
    return _getMeUseCase.execute();
  }

  Future<Result<UserProfile>> updateProfile(UpsertUserProfilePayload payload) {
    return _updateProfileUseCase.execute(payload);
  }
}
