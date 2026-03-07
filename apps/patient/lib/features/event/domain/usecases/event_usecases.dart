import 'package:patient/core/result/result.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/features/event/domain/repositories/event_repository.dart';

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

final class BindDoctorUseCase {
  const BindDoctorUseCase(this._repository);

  final EventRepository _repository;

  Future<Result<DoctorBindingStatus>> execute({required String bindingCode}) {
    return _repository.bindDoctor(bindingCode: bindingCode);
  }
}

final class UnbindDoctorUseCase {
  const UnbindDoctorUseCase(this._repository);

  final EventRepository _repository;

  Future<Result<DoctorBindingStatus>> execute() {
    return _repository.unbindDoctor();
  }
}

final class FetchDoctorBindingHistoryUseCase {
  const FetchDoctorBindingHistoryUseCase(this._repository);

  final EventRepository _repository;

  Future<Result<DoctorBindingHistoryResult>> execute({
    int limit = 20,
    String? cursor,
  }) {
    return _repository.fetchDoctorBindingHistory(limit: limit, cursor: cursor);
  }
}
