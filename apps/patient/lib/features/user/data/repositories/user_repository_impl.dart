import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:app_core/app_core.dart';
import 'package:patient/features/user/data/models/user_models.dart';
import 'package:patient/features/user/data/remote/user_api.dart';
import 'package:patient/features/user/domain/entities/user_avatar.dart';
import 'package:patient/features/user/domain/entities/user_basic_profile.dart';
import 'package:patient/features/user/domain/entities/user_profile.dart';
import 'package:patient/features/user/domain/repositories/user_repository.dart';

final class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(
    this._userApi, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final UserApi _userApi;
  final ApiCallExecutor _executor;

  @override
  Future<Result<UserProfile>> getMe() {
    return _executor.run(
      _userApi.getMe,
      (raw) => UserProfileResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserProfile>> updateProfile(UpsertUserProfilePayload payload) {
    final request = UpsertUserProfileRequestDto.fromDomain(payload);
    return _executor.run(
      () => _userApi.updateProfile(request),
      (raw) => UserProfileResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserBasicProfile>> getBasicProfile() {
    return _executor.run(
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
    return _executor.run(
      () => _userApi.updateBasicProfile(request),
      (raw) => UserBasicProfileResponseDto.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ).toDomain(),
    );
  }

  @override
  Future<Result<UserAvatarMeta>> uploadAvatar(File file) {
    return _executor.run(
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
}
