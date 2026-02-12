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
    return ApiEnvelope<T>(
      code: (json['code'] as num?)?.toInt() ?? -1,
      message: (json['message'] as String?) ?? 'Unknown error',
      data: decodeData(json['data']),
    );
  }

  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 0;

}
