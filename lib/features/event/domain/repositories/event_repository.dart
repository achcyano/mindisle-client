import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/event/domain/entities/event_entities.dart';

abstract interface class EventRepository {
  Future<Result<UserEventList>> fetchUserEvents();

  Future<Result<DoctorBindingStatus>> getDoctorBindingStatus();

  Future<Result<DoctorBindingStatus>> updateDoctorBindingStatus({
    required bool isBound,
  });
}
