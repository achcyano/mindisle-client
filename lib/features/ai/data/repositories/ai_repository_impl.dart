import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mindisle_client/core/network/api_envelope.dart';
import 'package:mindisle_client/core/network/error_mapper.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/ai/data/models/ai_models.dart';
import 'package:mindisle_client/features/ai/data/remote/ai_api.dart';
import 'package:mindisle_client/features/ai/domain/entities/ai_entities.dart';
import 'package:mindisle_client/features/ai/domain/repositories/ai_repository.dart';

final class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._api);

  final AiApi _api;

  @override
  Future<Result<AiConversation>> ensureConversation() async {
    final listResult = await _run(
      () => _api.listConversations(limit: 1),
      _decodeConversationList,
    );

    switch (listResult) {
      case Failure<List<AiConversation>>(error: final error):
        return Failure(error);
      case Success<List<AiConversation>>(data: final list):
        if (list.isNotEmpty) {
          return Success(list.first);
        }
    }

    return _run(() => _api.createConversation(), _decodeConversation);
  }

  @override
  Future<Result<List<AiChatMessage>>> fetchMessages({
    required int conversationId,
    int limit = 50,
    int? beforeMessageId,
  }) {
    return _run(
      () => _api.listMessages(
        conversationId: conversationId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      ),
      _decodeMessageList,
    );
  }

  @override
  Stream<AiStreamEvent> streamConversation({
    required int conversationId,
    required String userMessage,
    required String clientMessageId,
    double temperature = 0.7,
    int maxTokens = 2048,
    String? lastEventId,
  }) async* {
    try {
      await for (final frame in _api.streamConversation(
        conversationId: conversationId,
        userMessage: userMessage,
        clientMessageId: clientMessageId,
        temperature: temperature,
        maxTokens: maxTokens,
        lastEventId: lastEventId,
      )) {
        yield _toDomainEvent(frame);
      }
    } on DioException catch (e) {
      yield await _toStreamErrorEvent(e);
    } catch (e, st) {
      _logStreamException('streamConversation', e, st);

      yield const AiStreamEvent(
        type: AiStreamEventType.error,
        eventName: 'stream_exception',
        errorMessage: '回复中断，请稍后重试',
      );
    }
  }

  @override
  Stream<AiStreamEvent> resumeGeneration({
    required String generationId,
    String? lastEventId,
  }) async* {
    try {
      await for (final frame in _api.resumeGeneration(
        generationId: generationId,
        lastEventId: lastEventId,
      )) {
        yield _toDomainEvent(frame);
      }
    } on DioException catch (e) {
      yield await _toStreamErrorEvent(e);
    } catch (e, st) {
      _logStreamException('resumeGeneration', e, st);
      yield const AiStreamEvent(
        type: AiStreamEventType.error,
        eventName: 'stream_exception',
        errorMessage: '回复中断，请稍后重试',
      );
    }
  }

  Future<Result<T>> _run<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Object? rawData) decodeData,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<T>.fromJson(json, decodeData);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(
            code: envelope.code,
            message: envelope.message,
          ),
        );
      }

      final data = envelope.data;
      if (data == null) {
        return Failure(mapServerCodeToAppError(code: 50000, message: '响应数据为空'));
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

  AiConversation _decodeConversation(Object? rawData) {
    if (rawData is Map) {
      final map = Map<String, dynamic>.from(rawData);
      if (map['conversation'] is Map) {
        return AiConversationDto.fromJson(
          Map<String, dynamic>.from(map['conversation'] as Map),
        ).toDomain();
      }
      return AiConversationDto.fromJson(map).toDomain();
    }

    throw const FormatException('会话数据格式错误');
  }

  List<AiConversation> _decodeConversationList(Object? rawData) {
    final list = _extractList(
      rawData,
      fallbackKeys: const ['items', 'conversations', 'list'],
    );
    return list
        .whereType<Map>()
        .map(
          (item) => AiConversationDto.fromJson(
            Map<String, dynamic>.from(item),
          ).toDomain(),
        )
        .where((it) => it.conversationId > 0)
        .toList(growable: false);
  }

  List<AiChatMessage> _decodeMessageList(Object? rawData) {
    final list = _extractList(
      rawData,
      fallbackKeys: const ['items', 'messages', 'list'],
    );
    return list
        .whereType<Map>()
        .map(
          (item) =>
              AiMessageDto.fromJson(Map<String, dynamic>.from(item)).toDomain(),
        )
        .toList(growable: false);
  }

  List<dynamic> _extractList(
    Object? rawData, {
    required List<String> fallbackKeys,
  }) {
    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map) {
      final map = Map<String, dynamic>.from(rawData);
      for (final key in fallbackKeys) {
        final value = map[key];
        if (value is List) return value;
      }
    }

    return const <dynamic>[];
  }

  AiStreamEvent _toDomainEvent(AiSseFrame frame) {
    final data = _decodeFrameData(frame.data);
    final inferredGenerationId = _generationIdFromEventId(frame.id);
    final eventName = _resolveEventName(frame.event, data);
    _logSseFrame(frame: frame, data: data, eventName: eventName);

    switch (eventName) {
      case 'meta':
        final generationId =
            _readString(data, const ['generationId', 'generation_id']) ??
            inferredGenerationId;
        return AiStreamEvent(
          type: AiStreamEventType.meta,
          eventId: frame.id,
          eventName: eventName,
          generationId: generationId,
        );
      case 'delta':
        return AiStreamEvent(
          type: AiStreamEventType.delta,
          eventId: frame.id,
          eventName: eventName,
          generationId:
              _readString(data, const ['generationId', 'generation_id']) ??
              inferredGenerationId,
          delta: _extractDeltaText(data),
        );
      case 'usage':
        return AiStreamEvent(
          type: AiStreamEventType.usage,
          eventId: frame.id,
          eventName: eventName,
          generationId:
              _readString(data, const ['generationId', 'generation_id']) ??
              inferredGenerationId,
          usage: data,
        );
      case 'options':
        return AiStreamEvent(
          type: AiStreamEventType.options,
          eventId: frame.id,
          eventName: eventName,
          generationId:
              _readString(data, const ['generationId', 'generation_id']) ??
              inferredGenerationId,
          options: _decodeOptions(data['items']),
          optionSource: data['source'] as String?,
        );
      case 'done':
        return AiStreamEvent(
          type: AiStreamEventType.done,
          eventId: frame.id,
          eventName: eventName,
          generationId:
              _readString(data, const ['generationId', 'generation_id']) ??
              inferredGenerationId,
        );
      case 'error':
        return AiStreamEvent(
          type: AiStreamEventType.error,
          eventId: frame.id,
          eventName: eventName,
          generationId:
              _readString(data, const ['generationId', 'generation_id']) ??
              inferredGenerationId,
          errorCode: (data['code'] as num?)?.toInt(),
          errorMessage:
              _readString(data, const ['message', 'error']) ?? '回复中断，请稍后重试',
        );
      default:
        return AiStreamEvent(
          type: AiStreamEventType.unknown,
          eventId: frame.id,
          eventName: eventName,
          generationId:
              _readString(data, const ['generationId', 'generation_id']) ??
              inferredGenerationId,
        );
    }
  }

  Map<String, dynamic> _decodeFrameData(String raw) {
    if (raw.isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is String) {
        return <String, dynamic>{'text': decoded};
      }
    } catch (_) {
      return <String, dynamic>{'text': raw};
    }

    return <String, dynamic>{'text': raw};
  }

  String? _generationIdFromEventId(String? eventId) {
    if (eventId == null || eventId.isEmpty) return null;
    final separator = eventId.indexOf(':');
    if (separator <= 0) return null;
    return eventId.substring(0, separator);
  }

  String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  List<AiOption> _decodeOptions(Object? rawItems) {
    if (rawItems is! List) return const <AiOption>[];
    return rawItems
        .whereType<Map>()
        .map(
          (item) =>
              AiOptionDto.fromJson(Map<String, dynamic>.from(item)).toDomain(),
        )
        .where((item) => item.label.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  String? _extractDeltaText(Map<String, dynamic> data) {
    final direct = _readString(data, const ['delta', 'content', 'text']);
    if (direct != null) {
      return direct;
    }

    final nestedDelta = _readTextFromDynamic(data['delta']);
    if (nestedDelta != null) {
      return nestedDelta;
    }

    final nestedContent = _readTextFromDynamic(data['content']);
    if (nestedContent != null) {
      return nestedContent;
    }

    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final firstMap = Map<String, dynamic>.from(first);
        final choiceDelta = _readTextFromDynamic(firstMap['delta']);
        if (choiceDelta != null) {
          return choiceDelta;
        }
        final choiceText =
            _readTextFromDynamic(firstMap['text']) ??
            _readTextFromDynamic(firstMap['content']);
        if (choiceText != null) {
          return choiceText;
        }
      }
    }

    final contentList = data['content'];
    if (contentList is List && contentList.isNotEmpty) {
      for (final item in contentList) {
        final text = _readTextFromDynamic(item);
        if (text != null) {
          return text;
        }
      }
    }

    return null;
  }

  String? _readTextFromDynamic(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      for (final item in value) {
        final text = _readTextFromDynamic(item);
        if (text != null) {
          return text;
        }
      }
      return null;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final text = _readString(map, const [
        'text',
        'content',
        'delta',
        'value',
        'output_text',
      ]);
      if (text != null) {
        return text;
      }
    }
    return null;
  }

  String _resolveEventName(String rawEventName, Map<String, dynamic> data) {
    final normalizedFromFrame = _normalizeEventName(rawEventName);
    if (normalizedFromFrame != null && normalizedFromFrame != 'message') {
      return normalizedFromFrame;
    }

    final inferredFromData = _normalizeEventName(
      _readString(data, const ['event', 'type', 'name', 'kind']),
    );
    if (inferredFromData != null) {
      return inferredFromData;
    }

    if (_isDoneSentinel(data)) {
      return 'done';
    }
    if (data.containsKey('items') && data['items'] is List) {
      return 'options';
    }
    if (data.containsKey('promptTokens') ||
        data.containsKey('completionTokens') ||
        data.containsKey('totalTokens')) {
      return 'usage';
    }
    if (_extractDeltaText(data) != null) {
      return 'delta';
    }

    return 'message';
  }

  bool _isDoneSentinel(Map<String, dynamic> data) {
    final text = _readString(data, const ['text']);
    if (text == null) return false;
    return text.trim() == '[DONE]';
  }

  String? _normalizeEventName(String? raw) {
    if (raw == null) return null;
    final event = raw.trim().toLowerCase();
    if (event.isEmpty) return null;

    if (event.endsWith('.delta') || event == 'chunk' || event == 'token') {
      return 'delta';
    }
    if (event.endsWith('.done') ||
        event == 'complete' ||
        event == 'completed' ||
        event == 'finish' ||
        event == 'finished') {
      return 'done';
    }
    if (event.endsWith('.meta') || event == 'metadata') {
      return 'meta';
    }
    if (event == 'suggestions') {
      return 'options';
    }
    if (event == 'err' || event.endsWith('.error')) {
      return 'error';
    }

    return event;
  }

  void _logSseFrame({
    required AiSseFrame frame,
    required Map<String, dynamic> data,
    required String eventName,
  }) {
    if (!kDebugMode) return;
    final preview = frame.data.length > 180
        ? '${frame.data.substring(0, 180)}...'
        : frame.data;
    developer.log(
      '[AI-SSE] id=${frame.id ?? "-"} event=${frame.event} mapped=$eventName data=$preview',
      name: 'mindisle.ai.sse',
    );
    if (eventName == 'message') {
      developer.log(
        '[AI-SSE] unresolved event payload keys=${data.keys.toList()}',
        name: 'mindisle.ai.sse',
      );
    }
  }

  Future<AiStreamEvent> _toStreamErrorEvent(DioException exception) async {
    _ParsedError? parsed;
    try {
      parsed = await _parseErrorFromException(exception);
    } catch (_) {
      parsed = null;
    }
    final code = parsed?.code;
    if (code != null) {
      final mapped = mapServerCodeToAppError(
        code: code,
        message: parsed?.message ?? '',
        statusCode: exception.response?.statusCode,
      );
      return AiStreamEvent(
        type: AiStreamEventType.error,
        eventName: 'server_error',
        errorCode: code,
        errorMessage: mapped.message,
      );
    }

    final mapped = mapDioExceptionToAppError(exception);
    final message = parsed?.message;
    return AiStreamEvent(
      type: AiStreamEventType.error,
      eventName: _isRecoverableDioException(exception)
          ? 'recoverable_error'
          : 'request_error',
      errorCode: mapped.code,
      errorMessage: (message != null && message.isNotEmpty)
          ? message
          : mapped.message,
    );
  }

  bool _isRecoverableDioException(DioException exception) {
    return exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.connectionError ||
        exception.type == DioExceptionType.unknown;
  }

  Future<_ParsedError?> _parseErrorFromException(DioException exception) async {
    try {
      final raw = exception.response?.data;
      if (raw == null) return null;

      if (raw is Map<String, dynamic>) {
        return _parseErrorFromMap(raw);
      }
      if (raw is Map) {
        return _parseErrorFromMap(Map<String, dynamic>.from(raw));
      }
      if (raw is String) {
        return _parseErrorFromText(raw);
      }
      if (raw is ResponseBody) {
        final text = await _readResponseBody(raw);
        if (text.isEmpty) return null;
        final parsed = _parseErrorFromText(text);
        return parsed ?? _ParsedError(message: text);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  _ParsedError? _parseErrorFromText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return _parseErrorFromMap(decoded);
      }
      if (decoded is Map) {
        return _parseErrorFromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return _ParsedError(message: trimmed);
    }

    return _ParsedError(message: trimmed);
  }

  _ParsedError? _parseErrorFromMap(Map<String, dynamic> map) {
    var code = _toInt(map['code']);
    var message =
        _toNonEmptyString(map['message']) ?? _toNonEmptyString(map['error']);

    final nestedError = map['error'];
    if (nestedError is Map) {
      final nestedMap = Map<String, dynamic>.from(nestedError);
      code ??= _toInt(nestedMap['code']);
      message ??= _toNonEmptyString(nestedMap['message']);
    }

    if (code == null && message == null) {
      return null;
    }

    return _ParsedError(code: code, message: message ?? '');
  }

  Future<String> _readResponseBody(ResponseBody body) async {
    try {
      final buffer = BytesBuilder(copy: false);
      await for (final chunk in body.stream) {
        buffer.add(chunk);
      }

      final bytes = buffer.takeBytes();
      if (bytes.isEmpty) return '';
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _toNonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _logStreamException(String phase, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    developer.log(
      '[AI-SSE] $phase failed: $error',
      name: 'mindisle.ai.sse',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final class _ParsedError {
  const _ParsedError({this.code, this.message = ''});

  final int? code;
  final String message;
}
