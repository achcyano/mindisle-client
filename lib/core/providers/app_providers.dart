import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/config/app_config.dart';
import 'package:mindisle_client/core/network/dio_factory.dart';
import 'package:mindisle_client/core/network/token_refresh_service.dart';
import 'package:mindisle_client/shared/session/session_expired_signal.dart';
import 'package:mindisle_client/shared/session/session_store.dart';
import 'package:mindisle_client/shared/session/session_store_impl.dart';

final appConfigProvider = Provider<AppConfig>((_) => AppConfig.dev());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final sessionStoreProvider = Provider<SessionStore>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SessionStoreImpl(secureStorage);
});

final refreshDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return DioFactory.createRefreshDio(config);
});

final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  return TokenRefreshService(
    refreshDio: ref.watch(refreshDioProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  );
});

final appDioProvider = Provider<Dio>((ref) {
  return DioFactory.createAppDio(
    config: ref.watch(appConfigProvider),
    sessionStore: ref.watch(sessionStoreProvider),
    refreshService: ref.watch(tokenRefreshServiceProvider),
    onSessionExpired: ref.read(sessionExpiredEmitterProvider),
  );
});
