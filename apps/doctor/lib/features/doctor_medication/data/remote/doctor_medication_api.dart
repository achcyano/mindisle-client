import 'package:dio/dio.dart';

final class DoctorMedicationApi {
  DoctorMedicationApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchMedications({
    required int patientUserId,
    int limit = 50,
    String? cursor,
    bool? onlyActive,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/medications',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (onlyActive != null) 'onlyActive': onlyActive,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createMedication({
    required int patientUserId,
    required Map<String, dynamic> request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/medications',
      data: request,
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateMedication({
    required int patientUserId,
    required int medicationId,
    required Map<String, dynamic> request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/medications/$medicationId',
      data: request,
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> deleteMedication({
    required int patientUserId,
    required int medicationId,
  }) async {
    final response = await _dio.delete<dynamic>(
      '/api/v1/doctors/me/patients/$patientUserId/medications/$medicationId',
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return const <String, dynamic>{};
  }
}
