import 'dart:io';

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

  Future<Map<String, dynamic>> getBasicProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/me/basic-profile',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateBasicProfile(
    UpsertUserBasicProfileRequestDto request,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/users/me/basic-profile',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/users/me/avatar',
      data: formData,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Response<List<int>>> getAvatarBytes({String? ifNoneMatch}) {
    return _dio.get<List<int>>(
      '/api/v1/users/me/avatar',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          if (ifNoneMatch != null && ifNoneMatch.isNotEmpty)
            'If-None-Match': ifNoneMatch,
        },
        validateStatus: (status) {
          if (status == null) return false;
          return status == 304 || (status >= 200 && status < 300);
        },
      ),
    );
  }
}
