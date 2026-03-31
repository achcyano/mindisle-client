import 'package:dio/dio.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';

final class DoctorPatientApi {
  DoctorPatientApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchPatients({
    required DoctorPatientQuery query,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients',
      queryParameters: query.toQueryParameters(limit: limit, cursor: cursor),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/grouping',
      data: payload.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchGroupingHistory({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/grouping-history',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchPatientGroups() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patient-groups',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createPatientGroup({
    required String severityGroup,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctors/me/patient-groups',
      data: {'severityGroup': severityGroup},
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateDiagnosis({
    required int patientUserId,
    required DoctorPatientDiagnosisUpdatePayload payload,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/diagnosis',
      data: payload.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchPatientProfile({
    required int patientUserId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/profile',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Response<List<int>>> exportPatients() {
    return _dio.get<List<int>>(
      '/api/v1/doctors/me/patients/export',
      options: Options(responseType: ResponseType.bytes),
    );
  }
}
