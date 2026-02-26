import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/api_envelope.dart';
import 'package:mindisle_client/core/network/error_mapper.dart';
import 'package:mindisle_client/core/result/app_error.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/user/data/models/user_models.dart';
import 'package:mindisle_client/features/user/data/remote/user_api.dart';
import 'package:mindisle_client/features/user/domain/entities/user_avatar.dart';
import 'package:mindisle_client/features/user/domain/entities/user_basic_profile.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/domain/repositories/user_repository.dart';

final class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._userApi);

  final UserApi _userApi;

  @override
  Future<Result<UserProfile>> getMe() {
    return _run(
      _userApi.getMe,
      (raw) => UserProfileResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserProfile>> updateProfile(UpsertUserProfilePayload payload) {
    final request = UpsertUserProfileRequestDto.fromDomain(payload);
    return _run(
      () => _userApi.updateProfile(request),
      (raw) => UserProfileResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserBasicProfile>> getBasicProfile() {
    return _run(
      _userApi.getBasicProfile,
      (raw) => UserBasicProfileResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserBasicProfile>> updateBasicProfile(
    UpsertUserBasicProfilePayload payload,
  ) {
    final request = UpsertUserBasicProfileRequestDto.fromDomain(payload);
    return _run(
      () => _userApi.updateBasicProfile(request),
      (raw) => UserBasicProfileResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserAvatarMeta>> uploadAvatar(File file) {
    return _run(
      () => _userApi.uploadAvatar(file),
      (raw) => UserAvatarMetaResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserAvatarBinary>> getAvatar({String? ifNoneMatch}) async {
    try {
      final response = await _userApi.getAvatarBytes(ifNoneMatch: ifNoneMatch);
      final headers = response.headers;
      final eTag = headers.value('etag');
      final lastModified = headers.value('last-modified');
      final cacheControl = headers.value('cache-control');
      final statusCode = response.statusCode;

      if (statusCode == 304) {
        return Success(
          UserAvatarBinaryDto(
            isNotModified: true,
            bytes: null,
            eTag: eTag,
            lastModified: lastModified,
            cacheControl: cacheControl,
          ).toDomain(),
        );
      }

      if (statusCode == 404) {
        return Failure(_parseAvatarNotFoundError(response.data));
      }

      final rawBytes = response.data ?? const <int>[];
      final bytes = Uint8List.fromList(rawBytes);
      return Success(
        UserAvatarBinaryDto(
          isNotModified: false,
          bytes: bytes,
          eTag: eTag,
          lastModified: lastModified,
          cacheControl: cacheControl,
        ).toDomain(),
      );
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(mapServerCodeToAppError(code: 50000, message: e.toString()));
    }
  }

  AppError _parseAvatarNotFoundError(List<int>? rawData) {
    if (rawData != null && rawData.isNotEmpty) {
      try {
        final text = utf8.decode(rawData, allowMalformed: true).trim();
        if (text.isNotEmpty) {
          final decoded = jsonDecode(text);
          if (decoded is Map) {
            final map = Map<String, dynamic>.from(decoded);
            final code = (map['code'] as num?)?.toInt();
            final message = (map['message'] as String?) ?? '';
            if (code != null) {
              return mapServerCodeToAppError(
                code: code,
                message: message,
                statusCode: 404,
              );
            }
          }
        }
      } catch (_) {
        // Fallback to avatar-not-found semantics below.
      }
    }

    return mapServerCodeToAppError(
      code: 40403,
      message: 'Avatar not found',
      statusCode: 404,
    );
  }

  Future<Result<T>> _run<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Object? rawData) dataParser,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<T>.fromJson(json, dataParser);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(code: envelope.code, message: envelope.message),
        );
      }
      final data = envelope.data;
      if (data == null) {
        return Failure(
          mapServerCodeToAppError(
            code: 50000,
            message: 'Empty response data',
          ),
        );
      }
      return Success(data);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }
}
