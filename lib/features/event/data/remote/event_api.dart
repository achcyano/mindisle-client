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

  Future<Map<String, dynamic>> updateDoctorBindingStatus({
    required bool isBound,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/users/me/doctor-binding',
      data: <String, dynamic>{'isBound': isBound},
    );
    return response.data ?? const <String, dynamic>{};
  }
}
