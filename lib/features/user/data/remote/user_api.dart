import 'package:dio/dio.dart';
import 'package:mindisle_client/features/user/data/models/user_models.dart';

final class UserApi {
  UserApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/users/me');
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateProfile(
    UpsertUserProfileRequestDto request,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/users/me/profile',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }
}
