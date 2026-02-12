import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/api_envelope.dart';
import 'package:mindisle_client/core/network/request_flags.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/shared/session/session_models.dart';
import 'package:mindisle_client/shared/session/session_store.dart';

final class TokenRefreshService {
  TokenRefreshService({
    required Dio refreshDio,
    required SessionStore sessionStore,
  })  : _refreshDio = refreshDio,
        _sessionStore = sessionStore;

  final Dio _refreshDio;
  final SessionStore _sessionStore;
  Future<bool>? _refreshing;

  Future<bool> refresh() async {
    final current = _refreshing;
    if (current != null) return current;

    final future = _refreshInternal();
    _refreshing = future;
    try {
      return await future;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _refreshInternal() async {
    final session = await _sessionStore.readSession();
    if (session == null) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '$apiPrefix/auth/token/refresh',
        data: {'refreshToken': session.refreshToken},
        options: Options(
          headers: {'X-Device-Id': session.deviceId},
          extra: {RequestFlags.skipRefresh: true},
        ),
      );
      final envelope = ApiEnvelope<Map<String, dynamic>?>.fromJson(
        response.data ?? const {},
        (raw) => raw == null ? null : Map<String, dynamic>.from(raw as Map),
      );
      if (!envelope.isSuccess || envelope.data == null) return false;

      final data = envelope.data!;
      final userId = (data['userId'] as num?)?.toInt();
      final tokenJson = data['token'];
      if (userId == null || tokenJson is! Map) return false;

      final token = TokenPair(
        accessToken: tokenJson['accessToken'] as String? ?? '',
        refreshToken: tokenJson['refreshToken'] as String? ?? '',
        accessTokenExpiresInSeconds:
            (tokenJson['accessTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
        refreshTokenExpiresInSeconds:
            (tokenJson['refreshTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
      );
      if (token.accessToken.isEmpty || token.refreshToken.isEmpty) return false;

      await _sessionStore.saveSession(userId: userId, tokenPair: token);
      return true;
    } catch (_) {
      return false;
    }
  }
}
