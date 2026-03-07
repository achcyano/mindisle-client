import 'package:dio/dio.dart';

final class EventApi {
  EventApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listUserEvents() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/me/events',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getDoctorBindingStatus() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/me/doctor-binding',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> bindDoctor({required String bindingCode}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/me/doctor-binding/bind',
      data: <String, dynamic>{'bindingCode': bindingCode},
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> unbindDoctor() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/me/doctor-binding/unbind',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getDoctorBindingHistory({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/me/doctor-binding/history',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }
}
