import 'package:dio/dio.dart';
import 'package:app_core/src/network/api_envelope.dart';
import 'package:app_core/src/network/network_auth_strategy.dart';
import 'package:app_core/src/network/request_flags.dart';
import 'package:app_core/src/session/session_models.dart';
import 'package:app_core/src/session/session_store.dart';

final class TokenRefreshService {
  TokenRefreshService({
    required Dio refreshDio,
    required SessionStore sessionStore,
    required NetworkAuthStrategy authStrategy,
  }) : _refreshDio = refreshDio,
       _sessionStore = sessionStore,
       _authStrategy = authStrategy;

  final Dio _refreshDio;
  final SessionStore _sessionStore;
  final NetworkAuthStrategy _authStrategy;
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
        _authStrategy.refreshPath,
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
      final principalId = _resolvePrincipalId(data);
      final tokenJson = data['token'];
      if (principalId == null || tokenJson is! Map) return false;

      final token = TokenPair(
        accessToken: tokenJson['accessToken'] as String? ?? '',
        refreshToken: tokenJson['refreshToken'] as String? ?? '',
        accessTokenExpiresInSeconds:
            (tokenJson['accessTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
        refreshTokenExpiresInSeconds:
            (tokenJson['refreshTokenExpiresInSeconds'] as num?)?.toInt() ?? 0,
      );
      if (token.accessToken.isEmpty || token.refreshToken.isEmpty) return false;

      await _sessionStore.saveSession(
        principalId: principalId,
        tokenPair: token,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  int? _resolvePrincipalId(Map<String, dynamic> data) {
    for (final key in _authStrategy.principalIdKeys) {
      final raw = data[key];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
