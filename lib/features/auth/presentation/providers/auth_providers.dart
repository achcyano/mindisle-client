import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/features/auth/data/remote/auth_api.dart';
import 'package:mindisle_client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mindisle_client/features/auth/domain/repositories/auth_repository.dart';
import 'package:mindisle_client/features/auth/domain/usecases/auth_usecases.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(appDioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authApi: ref.watch(authApiProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  );
});

final sendSmsCodeUseCaseProvider = Provider<SendSmsCodeUseCase>((ref) {
  return SendSmsCodeUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final loginCheckUseCaseProvider = Provider<LoginCheckUseCase>((ref) {
  return LoginCheckUseCase(ref.watch(authRepositoryProvider));
});

final loginDirectUseCaseProvider = Provider<LoginDirectUseCase>((ref) {
  return LoginDirectUseCase(ref.watch(authRepositoryProvider));
});

final loginPasswordUseCaseProvider = Provider<LoginPasswordUseCase>((ref) {
  return LoginPasswordUseCase(ref.watch(authRepositoryProvider));
});

final refreshTokenUseCaseProvider = Provider<RefreshTokenUseCase>((ref) {
  return RefreshTokenUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});
