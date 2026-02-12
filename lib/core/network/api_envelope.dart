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
    final code = (json['code'] as num?)?.toInt() ?? -1;
    final message = (json['message'] as String?) ?? 'Unknown error';
    return ApiEnvelope<T>(
      code: code,
      message: message,
      data: code == 0 ? decodeData(json['data']) : null,
    );
  }

  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 0;

}
