import 'dart:convert';
import 'dart:typed_data';

import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/data/preference/const.dart';
import 'package:mindisle_client/features/user/domain/usecases/user_usecases.dart';
import 'package:mindisle_client/shared/session/session_store.dart';

final class AvatarCacheStore {
  const AvatarCacheStore();

  Uint8List? readForUser(int userId) {
    if (userId <= 0) return null;
    if (AppPrefs.cachedAvatarUserId.value != userId) return null;
    final raw = AppPrefs.cachedAvatarBase64.value;
    if (raw.isEmpty) return null;
    try {
      final bytes = base64Decode(raw);
      if (bytes.isEmpty) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  String? readETagForUser(int userId) {
    if (userId <= 0) return null;
    if (AppPrefs.cachedAvatarUserId.value != userId) return null;
    final eTag = AppPrefs.cachedAvatarETag.value.trim();
    return eTag.isEmpty ? null : eTag;
  }

  Future<void> saveForUser({
    required int userId,
    required Uint8List bytes,
    String? eTag,
  }) async {
    if (userId <= 0 || bytes.isEmpty) return;
    await Future.wait([
      AppPrefs.cachedAvatarUserId.set(userId),
      AppPrefs.cachedAvatarBase64.set(base64Encode(bytes)),
      AppPrefs.cachedAvatarETag.set((eTag ?? '').trim()),
    ]);
  }

  Future<void> clearForUser(int userId) async {
    if (userId <= 0) return;
    if (AppPrefs.cachedAvatarUserId.value != userId) return;
    await Future.wait([
      AppPrefs.cachedAvatarUserId.set(0),
      AppPrefs.cachedAvatarBase64.set(''),
      AppPrefs.cachedAvatarETag.set(''),
    ]);
  }
}

final class AvatarWarmupService {
  AvatarWarmupService({
    required GetAvatarUseCase getAvatarUseCase,
    required AvatarCacheStore cacheStore,
    required SessionStore sessionStore,
  }) : _getAvatarUseCase = getAvatarUseCase,
       _cacheStore = cacheStore,
       _sessionStore = sessionStore;

  final GetAvatarUseCase _getAvatarUseCase;
  final AvatarCacheStore _cacheStore;
  final SessionStore _sessionStore;

  Future<void> warmUp() async {
    try {
      final session = await _sessionStore.readSession();
      if (session == null || session.userId <= 0) return;

      final userId = session.userId;
      final cachedETag = _cacheStore.readETagForUser(userId);
      final result = await _getAvatarUseCase.execute(ifNoneMatch: cachedETag);
      if (result case Success(data: final avatar)) {
        if (avatar.isNotModified) return;
        final bytes = avatar.bytes;
        if (bytes == null || bytes.isEmpty) return;
        await _cacheStore.saveForUser(
          userId: userId,
          bytes: bytes,
          eTag: avatar.eTag,
        );
        return;
      }

      if (result case Failure(error: final error)) {
        if (error.code == 40403) {
          await _cacheStore.clearForUser(userId);
        }
      }
    } catch (_) {
      // Swallow warm-up errors to keep app launch/login flow smooth.
    }
  }
}
