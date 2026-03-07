import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';

abstract interface class DoctorBindingRepository {
  Future<Result<DoctorBindingCode>> createBindingCode();

  Future<Result<DoctorBindingHistoryResult>> fetchBindingHistory({
    int limit = 20,
    String? cursor,
    int? patientUserId,
  });
}
