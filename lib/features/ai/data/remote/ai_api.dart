import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mindisle_client/features/ai/data/models/ai_models.dart';

final class AiApi {
  AiApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createConversation({String? title}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/ai/conversations',
      data: {
        if (title != null && title.isNotEmpty) 'title': title,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> listConversations({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/ai/conversations',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> listMessages({
    required int conversationId,
    int limit = 50,
    int? beforeMessageId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/ai/conversations/$conversationId/messages',
      queryParameters: {
        'limit': limit,
        if (beforeMessageId != null) 'before': beforeMessageId,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Stream<AiSseFrame> streamConversation({
    required int conversationId,
    required String userMessage,
    required String clientMessageId,
    double temperature = 0.7,
    int maxTokens = 2048,
    String? lastEventId,
  }) {
    return _openSse(() {
      return _dio.post<ResponseBody>(
        '/api/v1/ai/conversations/$conversationId/stream',
        data: {
          'userMessage': userMessage,
          'clientMessageId': clientMessageId,
          'temperature': temperature,
          'maxTokens': maxTokens,
        },
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 10),
          headers: {
            Headers.acceptHeader: 'text/event-stream',
            Headers.contentTypeHeader: Headers.jsonContentType,
            if (lastEventId != null && lastEventId.isNotEmpty)
              'Last-Event-ID': lastEventId,
          },
        ),
      );
    });
  }

  Stream<AiSseFrame> resumeGeneration({
    required String generationId,
    String? lastEventId,
  }) {
    return _openSse(() {
      return _dio.get<ResponseBody>(
        '/api/v1/ai/generations/$generationId/stream',
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 10),
          headers: {
            Headers.acceptHeader: 'text/event-stream',
            if (lastEventId != null && lastEventId.isNotEmpty)
              'Last-Event-ID': lastEventId,
          },
        ),
      );
    });
  }

  Stream<AiSseFrame> _openSse(
    Future<Response<ResponseBody>> Function() request,
  ) async* {
    final response = await request();
    if (kDebugMode) {
      final contentType = response.headers.value(Headers.contentTypeHeader) ?? '-';
      developer.log(
        '[AI-SSE] open status=${response.statusCode} content-type=$contentType',
        name: 'mindisle.ai.sse.parser',
      );
    }
    final body = response.data;
    if (body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response<dynamic>(
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          data: const {'message': '流式响应为空'},
        ),
        type: DioExceptionType.badResponse,
        message: '流式响应为空',
      );
    }

    yield* _parseSse(body.stream);
  }

  Stream<AiSseFrame> _parseSse(Stream<List<int>> byteStream) async* {
    final builder = _SseFrameBuilder();
    var lineCount = 0;
    var frameCount = 0;
    try {
      await for (final line in _toLineStream(byteStream)) {
        lineCount += 1;
        _logSseLine(line);
        final frame = builder.consume(line);
        if (frame != null) {
          frameCount += 1;
          _logSseFrame(frame);
          yield frame;
        }
      }

      final tail = builder.flush();
      if (tail != null) {
        frameCount += 1;
        _logSseFrame(tail);
        yield tail;
      }

      if (kDebugMode) {
        developer.log(
          '[AI-SSE] stream closed, lines=$lineCount, frames=$frameCount',
          name: 'mindisle.ai.sse.parser',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          '[AI-SSE] parse failure lines=$lineCount frames=$frameCount error=$e',
          name: 'mindisle.ai.sse.parser',
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }

  Stream<String> _toLineStream(Stream<List<int>> byteStream) async* {
    var pending = '';
    await for (final chunk in byteStream) {
      if (chunk.isEmpty) continue;
      pending += utf8.decode(chunk, allowMalformed: true);
      final lines = pending.split('\n');
      pending = lines.removeLast();

      for (var line in lines) {
        if (line.endsWith('\r')) {
          line = line.substring(0, line.length - 1);
        }
        yield line;
      }
    }

    if (pending.isNotEmpty) {
      if (pending.endsWith('\r')) {
        pending = pending.substring(0, pending.length - 1);
      }
      yield pending;
    }
  }

  void _logSseLine(String line) {
    if (!kDebugMode) return;
    final preview = line.length > 160 ? '${line.substring(0, 160)}...' : line;
    developer.log(
      '[AI-SSE] line="$preview"',
      name: 'mindisle.ai.sse.parser',
    );
  }

  void _logSseFrame(AiSseFrame frame) {
    if (!kDebugMode) return;
    final preview = frame.data.length > 160 ? '${frame.data.substring(0, 160)}...' : frame.data;
    developer.log(
      '[AI-SSE] frame id=${frame.id ?? "-"} event=${frame.event} data=$preview',
      name: 'mindisle.ai.sse.parser',
    );
  }
}

final class _SseFrameBuilder {
  String? _currentId;
  String _currentEvent = 'message';
  final List<String> _dataLines = <String>[];

  AiSseFrame? consume(String line) {
    if (line.isEmpty) {
      return _emitAndResetIfNeeded();
    }
    if (line.startsWith(':')) {
      return null;
    }

    final field = _SseField.parse(line);
    _applyField(field);
    return null;
  }

  AiSseFrame? flush() {
    return _emitAndResetIfNeeded();
  }

  void _applyField(_SseField field) {
    switch (field.name) {
      case 'id':
        _currentId = field.value;
        return;
      case 'event':
        _currentEvent = field.value.isEmpty ? 'message' : field.value;
        return;
      case 'data':
        _dataLines.add(field.value);
        return;
      default:
        return;
    }
  }

  AiSseFrame? _emitAndResetIfNeeded() {
    final hasFrame = _currentId != null || _dataLines.isNotEmpty || _currentEvent != 'message';
    if (!hasFrame) {
      return null;
    }

    final frame = AiSseFrame(
      id: _currentId,
      event: _currentEvent,
      data: _dataLines.join('\n'),
    );
    _reset();
    return frame;
  }

  void _reset() {
    _currentId = null;
    _currentEvent = 'message';
    _dataLines.clear();
  }
}

final class _SseField {
  const _SseField({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;

  factory _SseField.parse(String line) {
    final separatorIndex = line.indexOf(':');
    final name = separatorIndex >= 0 ? line.substring(0, separatorIndex) : line;
    var value = separatorIndex >= 0 ? line.substring(separatorIndex + 1) : '';
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }
    return _SseField(name: name, value: value);
  }
}
