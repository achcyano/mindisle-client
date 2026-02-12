import 'package:mindisle_client/core/result/result.dart';
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
