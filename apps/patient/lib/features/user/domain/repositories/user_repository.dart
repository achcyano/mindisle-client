import 'dart:io';

import 'package:patient/core/result/result.dart';
import 'package:patient/features/user/domain/entities/user_avatar.dart';
import 'package:patient/features/user/domain/entities/user_basic_profile.dart';
import 'package:patient/features/user/domain/entities/user_profile.dart';

abstract interface class UserRepository {
  Future<Result<UserProfile>> getMe();

  Future<Result<UserProfile>> updateProfile(UpsertUserProfilePayload payload);

  Future<Result<UserBasicProfile>> getBasicProfile();

  Future<Result<UserBasicProfile>> updateBasicProfile(
    UpsertUserBasicProfilePayload payload,
  );

  Future<Result<UserAvatarMeta>> uploadAvatar(File file);

  Future<Result<UserAvatarBinary>> getAvatar({String? ifNoneMatch});
}
