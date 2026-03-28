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
}
