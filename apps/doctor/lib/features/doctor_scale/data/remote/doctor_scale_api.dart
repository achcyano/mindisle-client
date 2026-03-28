import 'package:dio/dio.dart';

final class DoctorScaleApi {
  DoctorScaleApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> generateAssessmentReport({
    required int patientUserId,
    int? days,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/assessment-report',
      data: {if (days != null) 'days': days},
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchLatestAssessmentReport({
    required int patientUserId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/assessment-reports/latest',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchAssessmentReports({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/assessment-reports',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchAssessmentReportDetail({
    required int patientUserId,
    required int reportId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/assessment-reports/$reportId',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchScaleAnswerRecords({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) async {
    final normalizedLimit = limit.clamp(1, 100).toInt();
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/scale-history',
      queryParameters: {
        'limit': normalizedLimit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchScaleSessionResult({
    required int patientUserId,
    required int sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/scales/sessions/$sessionId/result',
    );
    return response.data ?? const <String, dynamic>{};
  }
}
