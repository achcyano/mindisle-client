import 'package:dio/dio.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';

final class DoctorProfileApi {
  DoctorProfileApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/profile',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateProfile(
    DoctorProfileUpdatePayload payload,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/doctors/me/profile',
      data: payload.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchThresholds() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/doctors/me/thresholds',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateThresholds(
    DoctorThresholds payload,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/doctors/me/thresholds',
      data: payload.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }
}
