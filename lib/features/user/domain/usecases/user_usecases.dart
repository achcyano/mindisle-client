import 'dart:io';

import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/user/domain/entities/user_avatar.dart';
import 'package:mindisle_client/features/user/domain/entities/user_basic_profile.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/domain/repositories/user_repository.dart';

final class GetMeUseCase {
  const GetMeUseCase(this._repository);

  final UserRepository _repository;

  Future<Result<UserProfile>> execute() {
    return _repository.getMe();
  }
}

final class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final UserRepository _repository;

  Future<Result<UserProfile>> execute(UpsertUserProfilePayload payload) {
    return _repository.updateProfile(payload);
  }
}

final class GetBasicProfileUseCase {
  const GetBasicProfileUseCase(this._repository);

  final UserRepository _repository;

  Future<Result<UserBasicProfile>> execute() {
    return _repository.getBasicProfile();
  }
}

final class UpdateBasicProfileUseCase {
  const UpdateBasicProfileUseCase(this._repository);

  final UserRepository _repository;

  Future<Result<UserBasicProfile>> execute(
    UpsertUserBasicProfilePayload payload,
  ) {
    return _repository.updateBasicProfile(payload);
  }
}

final class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final UserRepository _repository;

  Future<Result<UserAvatarMeta>> execute(File file) {
    return _repository.uploadAvatar(file);
  }
}

final class GetAvatarUseCase {
  const GetAvatarUseCase(this._repository);

  final UserRepository _repository;

  Future<Result<UserAvatarBinary>> execute({String? ifNoneMatch}) {
    return _repository.getAvatar(ifNoneMatch: ifNoneMatch);
  }
}
