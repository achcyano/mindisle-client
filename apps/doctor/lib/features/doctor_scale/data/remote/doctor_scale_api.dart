import 'package:dio/dio.dart';

final class DoctorScaleApi {
  DoctorScaleApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchScaleTrends({
    required int patientUserId,
    int days = 180,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/scale-trends',
      queryParameters: {'days': days},
    );
    return response.data ?? const <String, dynamic>{};
  }

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
}
