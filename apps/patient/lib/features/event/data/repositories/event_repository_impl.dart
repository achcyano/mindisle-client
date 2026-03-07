import 'package:app_core/app_core.dart';
import 'package:patient/features/event/data/models/event_models.dart';
import 'package:patient/features/event/data/remote/event_api.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/features/event/domain/repositories/event_repository.dart';

final class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final EventApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<UserEventList>> fetchUserEvents() {
    return _executor.run(_api.listUserEvents, _decodeEventList);
  }

  @override
  Future<Result<DoctorBindingStatus>> getDoctorBindingStatus() {
    return _executor.run(_api.getDoctorBindingStatus, _decodeDoctorBindingStatus);
  }

  @override
  Future<Result<DoctorBindingStatus>> bindDoctor({required String bindingCode}) {
    return _executor.run(
      () => _api.bindDoctor(bindingCode: bindingCode),
      _decodeDoctorBindingStatus,
    );
  }

  @override
  Future<Result<DoctorBindingStatus>> unbindDoctor() {
    return _executor.run(_api.unbindDoctor, _decodeDoctorBindingStatus);
  }

  @override
  Future<Result<DoctorBindingHistoryResult>> fetchDoctorBindingHistory({
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.getDoctorBindingHistory(limit: limit, cursor: cursor),
      _decodeDoctorBindingHistory,
    );
  }

  UserEventList _decodeEventList(Object? rawData) {
    if (rawData is Map) {
      return UserEventListDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('Invalid event list payload');
  }

  DoctorBindingStatus _decodeDoctorBindingStatus(Object? rawData) {
    if (rawData is Map) {
      return DoctorBindingStatusDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('Invalid doctor binding payload');
  }

  DoctorBindingHistoryResult _decodeDoctorBindingHistory(Object? rawData) {
    if (rawData is Map) {
      return DoctorBindingHistoryResultDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('Invalid doctor binding history payload');
  }
}
