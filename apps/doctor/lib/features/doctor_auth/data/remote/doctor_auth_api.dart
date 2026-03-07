import 'package:dio/dio.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';

final class DoctorAuthApi {
  DoctorAuthApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> sendSmsCode({
    required String phone,
    required DoctorSmsPurpose purpose,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctor/auth/sms-codes',
      data: {
        'phone': phone,
        'purpose': doctorSmsPurposeToWire(purpose),
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String smsCode,
    required String password,
    required String fullName,
    String? title,
    String? hospital,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctor/auth/register',
      data: {
        'phone': phone,
        'smsCode': smsCode,
        'password': password,
        'fullName': fullName,
        if (title != null && title.isNotEmpty) 'title': title,
        if (hospital != null && hospital.isNotEmpty) 'hospital': hospital,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loginPassword({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctor/auth/login/password',
      data: {'phone': phone, 'password': password},
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctor/auth/token/refresh',
      data: {'refreshToken': refreshToken},
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctor/auth/password/reset',
      data: {
        'phone': phone,
        'smsCode': smsCode,
        'newPassword': newPassword,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctor/auth/password/change',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> logout({String? refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/doctor/auth/logout',
      data: {if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken': refreshToken},
    );
    return response.data ?? const <String, dynamic>{};
  }
}
