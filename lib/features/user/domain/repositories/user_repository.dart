import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';

abstract interface class UserRepository {
  Future<Result<UserProfile>> getMe();

  Future<Result<UserProfile>> updateProfile(UpsertUserProfilePayload payload);
}
