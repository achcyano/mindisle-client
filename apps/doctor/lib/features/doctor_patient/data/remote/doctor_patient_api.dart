import 'package:dio/dio.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';

final class DoctorPatientApi {
  DoctorPatientApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchPatients({
    int limit = 20,
    String? cursor,
    String? keyword,
    bool? abnormalOnly,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (abnormalOnly != null) 'abnormalOnly': abnormalOnly,
      },
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
