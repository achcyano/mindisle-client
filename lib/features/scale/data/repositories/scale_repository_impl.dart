import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/api_envelope.dart';
import 'package:mindisle_client/core/network/error_mapper.dart';
import 'package:mindisle_client/core/network/sse_parser.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/data/models/scale_models.dart';
import 'package:mindisle_client/features/scale/data/remote/scale_api.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/domain/repositories/scale_repository.dart';

final class ScaleRepositoryImpl implements ScaleRepository {
  ScaleRepositoryImpl(this._api);

  final ScaleApi _api;

  @override
  Future<Result<List<ScaleSummary>>> fetchScales({
    int limit = 20,
    String? cursor,
    String? status,
  }) {
    return _run(
      () => _api.listScales(limit: limit, cursor: cursor, status: status),
      _decodeScaleSummaryList,
    );
  }

  @override
  Future<Result<ScaleDetail>> fetchScaleDetail({required String scaleRef}) {
    return _run(
      () => _api.getScaleDetail(scaleRef: scaleRef),
      _decodeScaleDetail,
    );
  }

  @override
  Future<Result<ScaleCreateSessionResult>> createOrResumeSession({
    required int scaleId,
  }) {
    return _run(
      () => _api.createOrResumeSession(scaleId: scaleId),
      _decodeCreateSessionResult,
    );
  }

  @override
  Future<Result<ScaleSessionDetail>> fetchSessionDetail({
    required int sessionId,
  }) {
    return _run(
      () => _api.getSessionDetail(sessionId: sessionId),
      _decodeSessionDetail,
    );
  }

  @override
  Future<Result<bool>> saveAnswer({
    required int sessionId,
    required int questionId,
    required Object answer,
  }) {
    return _runNoData(
      () => _api.saveAnswer(
        sessionId: sessionId,
        questionId: questionId,
        answer: answer,
      ),
    );
  }

  @override
  Future<Result<bool>> submitSession({required int sessionId}) {
    return _runNoData(() => _api.submitSession(sessionId: sessionId));
  }

  @override
  Future<Result<ScaleResult>> fetchSessionResult({required int sessionId}) {
    return _run(
      () => _api.getSessionResult(sessionId: sessionId),
      _decodeScaleResult,
    );
  }

  @override
  Future<Result<List<ScaleHistoryItem>>> fetchHistory({
    int limit = 20,
    String? cursor,
  }) {
    return _run(
      () => _api.getHistory(limit: limit, cursor: cursor),
      _decodeHistoryItems,
    );
  }

  @override
  Future<Result<bool>> deleteSession({required int sessionId}) {
    return _runNoData(() => _api.deleteSession(sessionId: sessionId));
  }

  @override
  Stream<ScaleAssistEvent> assistQuestion({
    required int sessionId,
    required int questionId,
    required String userDraftAnswer,
  }) async* {
    try {
      await for (final frame in _api.assistQuestionStream(
        sessionId: sessionId,
        questionId: questionId,
        userDraftAnswer: userDraftAnswer,
      )) {
        yield _toAssistEvent(frame);
      }
    } on DioException catch (e) {
      yield _toAssistErrorFromDio(e);
    } catch (_) {
      yield const ScaleAssistEvent(
        type: ScaleAssistEventType.error,
        eventName: 'stream_exception',
        errorMessage: 'AI 回复中断，请稍后重试',
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

  Future<Result<bool>> _runNoData(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<Object?>.fromJson(json, (raw) => raw);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(
            code: envelope.code,
            message: envelope.message,
          ),
        );
      }
      return const Success(true);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }

  List<ScaleSummary> _decodeScaleSummaryList(Object? rawData) {
    final list = _extractList(
      rawData,
      fallbackKeys: const ['items', 'scales', 'list'],
    );
    return list
        .whereType<Map>()
        .map(
          (item) => ScaleSummaryDto.fromJson(
            Map<String, dynamic>.from(item),
          ).toDomain(),
        )
        .where((it) => it.scaleId > 0)
        .toList(growable: false);
  }

  ScaleDetail _decodeScaleDetail(Object? rawData) {
    if (rawData is Map) {
      return ScaleDetailDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('量表详情格式错误');
  }

  ScaleCreateSessionResult _decodeCreateSessionResult(Object? rawData) {
    if (rawData is Map) {
      return ScaleCreateSessionResultDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('会话创建结果格式错误');
  }

  ScaleSessionDetail _decodeSessionDetail(Object? rawData) {
    if (rawData is Map) {
      return ScaleSessionDetailDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('会话详情格式错误');
  }

  ScaleResult _decodeScaleResult(Object? rawData) {
    if (rawData is Map) {
      return ScaleResultDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('量表结果格式错误');
  }

  List<ScaleHistoryItem> _decodeHistoryItems(Object? rawData) {
    final list = _extractList(
      rawData,
      fallbackKeys: const ['items', 'history', 'list'],
    );
    return list
        .whereType<Map>()
        .map(
          (item) => ScaleHistoryItemDto.fromJson(
            Map<String, dynamic>.from(item),
          ).toDomain(),
        )
        .toList(growable: false);
  }

  List<dynamic> _extractList(
    Object? rawData, {
    required List<String> fallbackKeys,
  }) {
    if (rawData is List) return rawData;
    if (rawData is Map) {
      final map = Map<String, dynamic>.from(rawData);
      for (final key in fallbackKeys) {
        final value = map[key];
        if (value is List) return value;
      }
    }
    return const <dynamic>[];
  }

  ScaleAssistEvent _toAssistEvent(SseFrame frame) {
    final data = _decodeSseData(frame.data);
    final eventName = _resolveAssistEventName(frame.event, data);

    switch (eventName) {
      case 'meta':
        return ScaleAssistEvent(
          type: ScaleAssistEventType.meta,
          eventId: frame.id,
          eventName: eventName,
          generationId: _readString(data, const [
            'generationId',
            'generation_id',
          ]),
        );
      case 'delta':
        return ScaleAssistEvent(
          type: ScaleAssistEventType.delta,
          eventId: frame.id,
          eventName: eventName,
          generationId: _readString(data, const [
            'generationId',
            'generation_id',
          ]),
          delta: _extractDelta(data),
        );
      case 'done':
        return ScaleAssistEvent(
          type: ScaleAssistEventType.done,
          eventId: frame.id,
          eventName: eventName,
          generationId: _readString(data, const [
            'generationId',
            'generation_id',
          ]),
        );
      case 'error':
        return ScaleAssistEvent(
          type: ScaleAssistEventType.error,
          eventId: frame.id,
          eventName: eventName,
          generationId: _readString(data, const [
            'generationId',
            'generation_id',
          ]),
          errorCode: _readInt(data, const ['code']),
          errorMessage:
              _readString(data, const ['message', 'error']) ?? 'AI 回复中断，请稍后重试',
        );
      default:
        return ScaleAssistEvent(
          type: ScaleAssistEventType.unknown,
          eventId: frame.id,
          eventName: eventName,
        );
    }
  }

  ScaleAssistEvent _toAssistErrorFromDio(DioException exception) {
    final response = exception.response;
    final data = response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final code = _readInt(map, const ['code']);
      final message =
          _readString(map, const ['message']) ??
          mapDioExceptionToAppError(exception).message;
      return ScaleAssistEvent(
        type: ScaleAssistEventType.error,
        eventName: 'request_error',
        errorCode: code,
        errorMessage: message,
      );
    }
    return ScaleAssistEvent(
      type: ScaleAssistEventType.error,
      eventName: 'request_error',
      errorCode: mapDioExceptionToAppError(exception).code,
      errorMessage: mapDioExceptionToAppError(exception).message,
    );
  }

  Map<String, dynamic> _decodeSseData(String raw) {
    if (raw.isEmpty) return const <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is String) return <String, dynamic>{'text': decoded};
    } catch (_) {
      return <String, dynamic>{'text': raw};
    }
    return <String, dynamic>{'text': raw};
  }

  String _resolveAssistEventName(
    String rawEventName,
    Map<String, dynamic> data,
  ) {
    final normalized = _normalizeEventName(rawEventName);
    if (normalized != null && normalized != 'message') {
      return normalized;
    }
    final inferred = _normalizeEventName(
      _readString(data, const ['event', 'type', 'name', 'kind']),
    );
    if (inferred != null) return inferred;
    if (_extractDelta(data) != null) return 'delta';
    return 'message';
  }

  String? _normalizeEventName(String? raw) {
    if (raw == null) return null;
    final event = raw.trim().toLowerCase();
    if (event.isEmpty) return null;
    if (event.endsWith('.delta') || event == 'chunk') return 'delta';
    if (event.endsWith('.done') || event == 'completed') return 'done';
    if (event == 'err' || event.endsWith('.error')) return 'error';
    return event;
  }

  String? _extractDelta(Map<String, dynamic> data) {
    return _readString(data, const ['delta', 'content', 'text']);
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

  int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
