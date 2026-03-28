import 'package:app_core/app_core.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';

abstract interface class DoctorPatientRepository {
  Future<Result<DoctorPatientListResult>> fetchPatients({
    required DoctorPatientQuery query,
    int limit = 20,
    String? cursor,
  });

  Future<Result<DoctorPatientGrouping>> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  });

  Future<Result<List<DoctorPatientGroupingHistoryItem>>> fetchGroupingHistory({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  });
}
