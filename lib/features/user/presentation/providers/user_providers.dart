import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/features/user/data/remote/user_api.dart';
import 'package:mindisle_client/features/user/data/repositories/user_repository_impl.dart';
import 'package:mindisle_client/features/user/domain/repositories/user_repository.dart';
import 'package:mindisle_client/features/user/domain/usecases/user_usecases.dart';

final userApiProvider = Provider<UserApi>((ref) {
  return UserApi(ref.watch(appDioProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userApiProvider));
});

final getMeUseCaseProvider = Provider<GetMeUseCase>((ref) {
  return GetMeUseCase(ref.watch(userRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(userRepositoryProvider));
});

final getBasicProfileUseCaseProvider = Provider<GetBasicProfileUseCase>((ref) {
  return GetBasicProfileUseCase(ref.watch(userRepositoryProvider));
});

final updateBasicProfileUseCaseProvider =
    Provider<UpdateBasicProfileUseCase>((ref) {
      return UpdateBasicProfileUseCase(ref.watch(userRepositoryProvider));
    });

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(userRepositoryProvider));
});

final getAvatarUseCaseProvider = Provider<GetAvatarUseCase>((ref) {
  return GetAvatarUseCase(ref.watch(userRepositoryProvider));
});
