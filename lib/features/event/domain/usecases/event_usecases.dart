import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/event/domain/entities/event_entities.dart';
import 'package:mindisle_client/features/event/domain/repositories/event_repository.dart';

final class FetchUserEventsUseCase {
  const FetchUserEventsUseCase(this._repository);

  final EventRepository _repository;

  Future<Result<UserEventList>> execute() {
    return _repository.fetchUserEvents();
  }
}

final class GetDoctorBindingStatusUseCase {
  const GetDoctorBindingStatusUseCase(this._repository);

  final EventRepository _repository;

  Future<Result<DoctorBindingStatus>> execute() {
    return _repository.getDoctorBindingStatus();
  }
}

final class UpdateDoctorBindingStatusUseCase {
  const UpdateDoctorBindingStatusUseCase(this._repository);

  final EventRepository _repository;

  Future<Result<DoctorBindingStatus>> execute({required bool isBound}) {
    return _repository.updateDoctorBindingStatus(isBound: isBound);
  }
}
