import 'package:dio/dio.dart';
import 'package:patient/features/medication/data/models/medication_models.dart';

final class MedicationApi {
  MedicationApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listMedications({
    int limit = 50,
    String? cursor,
    bool? onlyActive,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/users/me/medications',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (onlyActive != null) 'onlyActive': onlyActive,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createMedication(
    UpsertMedicationRequestDto request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users/me/medications',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateMedication({
    required int medicationId,
    required UpsertMedicationRequestDto request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/users/me/medications/$medicationId',
      data: request.toJson(),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> deleteMedication({
    required int medicationId,
  }) async {
    final response = await _dio.delete<dynamic>(
      '/api/v1/users/me/medications/$medicationId',
    );
    return _toMap(response.data);
  }

  Map<String, dynamic> _toMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }
}
