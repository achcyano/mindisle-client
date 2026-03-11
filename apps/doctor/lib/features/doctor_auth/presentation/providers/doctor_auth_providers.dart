import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/features/doctor_auth/data/remote/doctor_auth_api.dart';
import 'package:doctor/features/doctor_auth/data/repositories/doctor_auth_repository_impl.dart';
import 'package:doctor/features/doctor_auth/domain/repositories/doctor_auth_repository.dart';
import 'package:doctor/features/doctor_auth/domain/usecases/doctor_auth_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorAuthApiProvider = Provider<DoctorAuthApi>((ref) {
  return DoctorAuthApi(
    ref.watch(appDioProvider),
    scope: ref.watch(authScopeConfigProvider),
  );
});

final doctorAuthRepositoryProvider = Provider<DoctorAuthRepository>((ref) {
  return DoctorAuthRepositoryImpl(
    authApi: ref.watch(doctorAuthApiProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  );
});

final sendDoctorSmsCodeUseCaseProvider = Provider<SendDoctorSmsCodeUseCase>((
  ref,
) {
  return SendDoctorSmsCodeUseCase(ref.watch(doctorAuthRepositoryProvider));
});

final doctorRegisterUseCaseProvider = Provider<DoctorRegisterUseCase>((ref) {
  return DoctorRegisterUseCase(ref.watch(doctorAuthRepositoryProvider));
});

final doctorLoginCheckUseCaseProvider = Provider<DoctorLoginCheckUseCase>((
  ref,
) {
  return DoctorLoginCheckUseCase(ref.watch(doctorAuthRepositoryProvider));
});

final doctorLoginDirectUseCaseProvider = Provider<DoctorLoginDirectUseCase>((
  ref,
) {
  return DoctorLoginDirectUseCase(ref.watch(doctorAuthRepositoryProvider));
});

final doctorLoginPasswordUseCaseProvider = Provider<DoctorLoginPasswordUseCase>(
  (ref) {
    return DoctorLoginPasswordUseCase(ref.watch(doctorAuthRepositoryProvider));
  },
);

final doctorRefreshTokenUseCaseProvider = Provider<DoctorRefreshTokenUseCase>((
  ref,
) {
  return DoctorRefreshTokenUseCase(ref.watch(doctorAuthRepositoryProvider));
});

final doctorResetPasswordUseCaseProvider = Provider<DoctorResetPasswordUseCase>(
  (ref) {
    return DoctorResetPasswordUseCase(ref.watch(doctorAuthRepositoryProvider));
  },
);

final doctorChangePasswordUseCaseProvider =
    Provider<DoctorChangePasswordUseCase>((ref) {
      return DoctorChangePasswordUseCase(
        ref.watch(doctorAuthRepositoryProvider),
      );
    });

final doctorLogoutUseCaseProvider = Provider<DoctorLogoutUseCase>((ref) {
  return DoctorLogoutUseCase(ref.watch(doctorAuthRepositoryProvider));
});
