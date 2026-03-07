import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_auth/data/models/doctor_auth_models.dart';
import 'package:doctor/features/doctor_auth/data/remote/doctor_auth_api.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/domain/repositories/doctor_auth_repository.dart';

final class DoctorAuthRepositoryImpl implements DoctorAuthRepository {
  DoctorAuthRepositoryImpl({
    required DoctorAuthApi api,
    required SessionStore sessionStore,
    ApiCallExecutor executor = const ApiCallExecutor(),
  })  : _api = api,
        _sessionStore = sessionStore,
        _executor = executor;

  final DoctorAuthApi _api;
  final SessionStore _sessionStore;
  final ApiCallExecutor _executor;

  @override
  Future<Result<void>> sendSmsCode({
    required String phone,
    required DoctorSmsPurpose purpose,
  }) async {
    final result = await _executor.runNoData(
      () => _api.sendSmsCode(phone: phone, purpose: purpose),
    );
    return _toVoid(result);
  }

  @override
  Future<Result<DoctorAuthSession>> register({
    required String phone,
    required String smsCode,
    required String password,
    required String fullName,
    String? title,
    String? hospital,
  }) async {
    final result = await _executor.run(
      () => _api.register(
        phone: phone,
        smsCode: smsCode,
        password: password,
        fullName: fullName,
        title: title,
        hospital: hospital,
      ),
      (raw) => DoctorAuthResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
    await _saveIfSuccess(result);
    return result;
  }

  @override
  Future<Result<DoctorAuthSession>> loginPassword({
    required String phone,
    required String password,
  }) async {
    final result = await _executor.run(
      () => _api.loginPassword(phone: phone, password: password),
      (raw) => DoctorAuthResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
    await _saveIfSuccess(result);
    return result;
  }

  @override
  Future<Result<DoctorAuthSession>> refreshToken() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return Failure(mapServerCodeToAppError(code: 40100, message: 'Missing refresh token'));
    }

    final result = await _executor.run(
      () => _api.refreshToken(refreshToken: refreshToken),
      (raw) => DoctorAuthResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
    await _saveIfSuccess(result);
    return result;
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) async {
    final result = await _executor.runNoData(
      () => _api.resetPassword(
        phone: phone,
        smsCode: smsCode,
        newPassword: newPassword,
      ),
    );
    if (result is Success<bool>) {
      await _sessionStore.clearSession();
    }
    return _toVoid(result);
  }

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return _toVoid(
      await _executor.runNoData(
        () => _api.changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        ),
      ),
    );
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    final result = await _executor.runNoData(
      () => _api.logout(refreshToken: refreshToken),
    );
    if (result is Success<bool>) {
      await _sessionStore.clearSession();
    }
    return _toVoid(result);
  }

  Future<void> _saveIfSuccess(Result<DoctorAuthSession> result) async {
    if (result case Success<DoctorAuthSession>(data: final data)) {
      await _sessionStore.saveSession(
        principalId: data.doctorId,
        tokenPair: data.tokenPair,
      );
    }
  }

  Result<void> _toVoid(Result<bool> result) {
    return switch (result) {
      Success<bool>() => const Success(null),
      Failure<bool>(error: final error) => Failure(error),
    };
  }
}
