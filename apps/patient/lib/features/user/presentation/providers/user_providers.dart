import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/providers/app_providers.dart';
import 'package:patient/features/user/data/remote/user_api.dart';
import 'package:patient/features/user/data/repositories/user_repository_impl.dart';
import 'package:patient/features/user/domain/repositories/user_repository.dart';
import 'package:patient/features/user/domain/usecases/user_usecases.dart';
import 'package:patient/features/user/presentation/profile/avatar_cache_store.dart';
import 'package:patient/features/user/presentation/profile/basic_profile_cache_store.dart';

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

final updateBasicProfileUseCaseProvider = Provider<UpdateBasicProfileUseCase>((
  ref,
) {
  return UpdateBasicProfileUseCase(ref.watch(userRepositoryProvider));
});

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(userRepositoryProvider));
});

final getAvatarUseCaseProvider = Provider<GetAvatarUseCase>((ref) {
  return GetAvatarUseCase(ref.watch(userRepositoryProvider));
});

final avatarCacheStoreProvider = Provider<AvatarCacheStore>((ref) {
  return const AvatarCacheStore();
});

final basicProfileCacheStoreProvider = Provider<BasicProfileCacheStore>((ref) {
  return const BasicProfileCacheStore();
});

final avatarWarmupServiceProvider = Provider<AvatarWarmupService>((ref) {
  return AvatarWarmupService(
    getAvatarUseCase: ref.watch(getAvatarUseCaseProvider),
    cacheStore: ref.watch(avatarCacheStoreProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  );
});

final basicProfileWarmupServiceProvider = Provider<BasicProfileWarmupService>((
  ref,
) {
  return BasicProfileWarmupService(
    getBasicProfileUseCase: ref.watch(getBasicProfileUseCaseProvider),
    cacheStore: ref.watch(basicProfileCacheStoreProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  );
});
