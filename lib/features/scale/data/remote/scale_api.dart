import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/sse_parser.dart';

final class ScaleApi {
  ScaleApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> listScales({
    int limit = 20,
    String? cursor,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/scales',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getScaleDetail({
    required String scaleRef,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/scales/$scaleRef',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createOrResumeSession({
    required int scaleId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/scales/$scaleId/sessions',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getSessionDetail({
    required int sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/scales/sessions/$sessionId',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> saveSingleChoiceAnswer({
    required int sessionId,
    required int questionId,
    required int optionId,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/scales/sessions/$sessionId/answers/$questionId',
      data: <String, dynamic>{
        'answer': <String, dynamic>{'optionId': optionId},
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> submitSession({required int sessionId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/scales/sessions/$sessionId/submit',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getSessionResult({
    required int sessionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/scales/sessions/$sessionId/result',
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getHistory({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/scales/history',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> deleteSession({required int sessionId}) async {
    final response = await _dio.delete<dynamic>(
      '/api/v1/scales/sessions/$sessionId',
    );
    return _toMap(response.data);
  }

  Stream<SseFrame> assistQuestionStream({
    required int sessionId,
    required int questionId,
    required String userDraftAnswer,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      '/api/v1/scales/assist/stream',
      data: <String, dynamic>{
        'sessionId': sessionId,
        'questionId': questionId,
        'userDraftAnswer': userDraftAnswer,
      },
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 5),
        headers: const <String, String>{
          Headers.acceptHeader: 'text/event-stream',
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
    );

    final body = response.data;
    if (body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response<dynamic>(
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          data: const <String, dynamic>{'message': '流式响应为空'},
        ),
        type: DioExceptionType.badResponse,
        message: '流式响应为空',
      );
    }

    yield* SseParser.parse(body.stream);
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
