import 'package:dio/dio.dart';

final class DoctorMonitorApi {
  DoctorMonitorApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchSideEffectSummary({
    required int patientUserId,
    int days = 30,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/side-effects/summary',
      queryParameters: {'days': days},
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchWeightTrend({
    required int patientUserId,
    int days = 180,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/patients/$patientUserId/weight-trend',
      queryParameters: {'days': days},
    );
    return response.data ?? const <String, dynamic>{};
  }
}
