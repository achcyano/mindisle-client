final class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.code,
    required this.message,
    required this.data,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw) decodeData,
  ) {
    final parsedCode = (json['code'] as num?)?.toInt();
    final code = parsedCode ?? 0;
    final message = (json['message'] as String?) ??
        (code == 0 ? '\u6210\u529f' : '\u8bf7\u6c42\u5931\u8d25');
    final rawData = json.containsKey('data') ? json['data'] : json;

    return ApiEnvelope<T>(
      code: code,
      message: message,
      data: code == 0 ? decodeData(rawData) : null,
    );
  }

  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 0;
}
