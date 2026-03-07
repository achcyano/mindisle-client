import 'package:patient/core/result/result.dart';
import 'package:patient/data/preference/const.dart';
import 'package:patient/features/user/domain/entities/user_basic_profile.dart';
import 'package:patient/features/user/domain/entities/user_profile.dart';
import 'package:patient/features/user/domain/usecases/user_usecases.dart';
import 'package:patient/shared/session/session_store.dart';

final class BasicProfileCacheStore {
  const BasicProfileCacheStore();

  UserBasicProfile? readForUser(int userId) {
    if (userId <= 0) return null;
    if (AppPrefs.cachedBasicProfileUserId.value != userId) return null;

    final raw = AppPrefs.cachedBasicProfileData.value;
    if (raw.isEmpty) return null;

    try {
      return _fromMap(raw, userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveForUser(UserBasicProfile profile) async {
    if (profile.userId <= 0) return;
    await Future.wait([
      AppPrefs.cachedBasicProfileUserId.set(profile.userId),
      AppPrefs.cachedBasicProfileData.set(_toMap(profile)),
    ]);
  }

  Future<void> clearForUser(int userId) async {
    if (userId <= 0) return;
    if (AppPrefs.cachedBasicProfileUserId.value != userId) return;
    await Future.wait([
      AppPrefs.cachedBasicProfileUserId.set(0),
      AppPrefs.cachedBasicProfileData.set(<String, dynamic>{}),
    ]);
  }

  Map<String, dynamic> _toMap(UserBasicProfile profile) {
    return <String, dynamic>{
      'userId': profile.userId,
      'fullName': profile.fullName,
      'gender': profile.gender.name,
      'birthDate': profile.birthDate,
      'heightCm': profile.heightCm,
      'weightKg': profile.weightKg,
      'waistCm': profile.waistCm,
      'usesTcm': profile.usesTcm,
      'diseaseHistory': profile.diseaseHistory,
    };
  }

  UserBasicProfile _fromMap(Map<String, dynamic> map, int fallbackUserId) {
    final diseaseHistoryRaw = map['diseaseHistory'];
    final diseaseHistory = diseaseHistoryRaw is List
        ? diseaseHistoryRaw
              .map((item) => item.toString())
              .toList(growable: false)
        : const <String>[];

    final genderRaw = map['gender']?.toString() ?? '';
    final gender = UserGender.values.firstWhere(
      (item) => item.name == genderRaw,
      orElse: () => UserGender.unknown,
    );

    return UserBasicProfile(
      userId: _toInt(map['userId']) > 0
          ? _toInt(map['userId'])
          : fallbackUserId,
      fullName: map['fullName'] as String?,
      gender: gender,
      birthDate: map['birthDate'] as String?,
      heightCm: _toDouble(map['heightCm']),
      weightKg: _toDouble(map['weightKg']),
      waistCm: _toDouble(map['waistCm']),
      usesTcm: _toBool(map['usesTcm'], fallback: false),
      diseaseHistory: diseaseHistory,
    );
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  double? _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool _toBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }
}

final class BasicProfileWarmupService {
  BasicProfileWarmupService({
    required GetBasicProfileUseCase getBasicProfileUseCase,
    required BasicProfileCacheStore cacheStore,
    required SessionStore sessionStore,
  }) : _getBasicProfileUseCase = getBasicProfileUseCase,
       _cacheStore = cacheStore,
       _sessionStore = sessionStore;

  final GetBasicProfileUseCase _getBasicProfileUseCase;
  final BasicProfileCacheStore _cacheStore;
  final SessionStore _sessionStore;

  Future<void> warmUp() async {
    try {
      final session = await _sessionStore.readSession();
      if (session == null || session.principalId <= 0) return;

      final result = await _getBasicProfileUseCase.execute();
      if (result case Success(data: final profile)) {
        await _cacheStore.saveForUser(profile);
      }
    } catch (_) {
      // Swallow warm-up errors to keep app launch/login flow smooth.
    }
  }
}
