import 'package:dio/dio.dart';

final class DoctorBindingApi {
  DoctorBindingApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createBindingCode() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctors/me/binding-codes',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchBindingHistory({
    int limit = 20,
    String? cursor,
    int? patientUserId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/binding-history',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (patientUserId != null) 'patientUserId': patientUserId,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }
}
