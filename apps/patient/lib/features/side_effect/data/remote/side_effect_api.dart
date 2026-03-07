import 'package:dio/dio.dart';
import 'package:patient/features/side_effect/data/models/side_effect_models.dart';

final class SideEffectApi {
  SideEffectApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createSideEffect(
    CreateSideEffectRequestDto request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/me/side-effects',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> listSideEffects({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/me/side-effects',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }
}
