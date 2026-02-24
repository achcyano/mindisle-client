import 'dart:convert';

final class SseFrame {
  const SseFrame({this.id, required this.event, required this.data});

  final String? id;
  final String event;
  final String data;
}

final class SseParser {
  const SseParser._();

  static Stream<SseFrame> parse(Stream<List<int>> byteStream) async* {
    final builder = _SseFrameBuilder();
    await for (final line in _toLineStream(byteStream)) {
      final frame = builder.consume(line);
      if (frame != null) {
        yield frame;
      }
    }

    final tail = builder.flush();
    if (tail != null) {
      yield tail;
    }
  }

  static Stream<String> _toLineStream(Stream<List<int>> byteStream) async* {
    var pending = '';
    final textStream = byteStream.cast<List<int>>().transform(
      const Utf8Decoder(allowMalformed: true),
    );
    await for (final chunk in textStream) {
      if (chunk.isEmpty) continue;

      pending += chunk;
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
}

final class _SseFrameBuilder {
  String? _currentId;
  String _currentEvent = 'message';
  final List<String> _dataLines = <String>[];

  SseFrame? consume(String line) {
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

  SseFrame? flush() {
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

  SseFrame? _emitAndResetIfNeeded() {
    final hasFrame =
        _currentId != null ||
        _dataLines.isNotEmpty ||
        _currentEvent != 'message';
    if (!hasFrame) {
      return null;
    }

    final frame = SseFrame(
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
  const _SseField({required this.name, required this.value});

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
