import 'package:patient/core/result/result.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';

abstract interface class EventRepository {
  Future<Result<UserEventList>> fetchUserEvents();

  Future<Result<DoctorBindingStatus>> getDoctorBindingStatus();

  Future<Result<DoctorBindingStatus>> bindDoctor({
    required String bindingCode,
  });

  Future<Result<DoctorBindingStatus>> unbindDoctor();

  Future<Result<DoctorBindingHistoryResult>> fetchDoctorBindingHistory({
    int limit = 20,
    String? cursor,
  });
}
