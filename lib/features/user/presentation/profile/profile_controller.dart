import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/data/preference/const.dart';
import 'package:mindisle_client/features/user/domain/entities/user_basic_profile.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/avatar_cache_store.dart';
import 'package:mindisle_client/features/user/presentation/profile/avatar_image_processor.dart';
import 'package:mindisle_client/features/user/presentation/profile/basic_profile_cache_store.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/features/user/presentation/providers/user_providers.dart';

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
      return ProfileController(ref);
    });

final class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(
    this._ref, {
    ImagePicker? picker,
    AvatarImageProcessor? avatarImageProcessor,
    AvatarCacheStore? avatarCacheStore,
    BasicProfileCacheStore? basicProfileCacheStore,
  }) : _picker = picker ?? ImagePicker(),
       _avatarImageProcessor = avatarImageProcessor ?? AvatarImageProcessor(),
       _avatarCacheStore = avatarCacheStore ?? const AvatarCacheStore(),
       _basicProfileCacheStore =
           basicProfileCacheStore ?? const BasicProfileCacheStore(),
       super(const ProfileState());

  final Ref _ref;
  final ImagePicker _picker;
  final AvatarImageProcessor _avatarImageProcessor;
  final AvatarCacheStore _avatarCacheStore;
  final BasicProfileCacheStore _basicProfileCacheStore;

  Future<void> initialize({bool refresh = false}) async {
    final userId = AppPrefs.sessionUserId.value;
    final cachedProfile = _basicProfileCacheStore.readForUser(userId);
    final cachedAvatarBytes = _avatarCacheStore.readForUser(userId);
    final cachedAvatarETag = _avatarCacheStore.readETagForUser(userId);
    final seedProfile = state.profile ?? cachedProfile;
    final seedAvatarBytes = state.avatarBytes ?? cachedAvatarBytes;
    final seedAvatarETag = state.avatarETag ?? cachedAvatarETag;

    if (refresh) {
      if (state.isRefreshing) return;
      state = state.copyWith(
        initialized: true,
        isRefreshing: true,
        errorMessage: null,
        profile: seedProfile,
        avatarBytes: seedAvatarBytes,
        avatarETag: seedAvatarETag,
      );
    } else {
      if (state.isLoading || state.isRefreshing) return;
      state = state.copyWith(
        initialized: true,
        isLoading: seedProfile == null,
        isRefreshing: seedProfile != null,
        errorMessage: null,
        profile: seedProfile,
        avatarBytes: seedAvatarBytes,
        avatarETag: seedAvatarETag,
      );
    }
    if (seedProfile != null) {
      _hydrateProfileInputs(seedProfile);
    }

    final profileResult = await _ref
        .read(getBasicProfileUseCaseProvider)
        .execute();
    switch (profileResult) {
      case Failure(error: final error):
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          errorMessage: error.message,
        );
        return;
      case Success(data: final profile):
        await _basicProfileCacheStore.saveForUser(profile);
        _applyProfileToState(profile);
    }

    final avatarResult = await _ref
        .read(getAvatarUseCaseProvider)
        .execute(ifNoneMatch: state.avatarETag);

    switch (avatarResult) {
      case Failure(error: final error):
        if (error.code == 40403) {
          await _avatarCacheStore.clearForUser(userId);
          state = state.copyWith(
            avatarBytes: null,
            avatarETag: null,
            isLoading: false,
            isRefreshing: false,
          );
          return;
        }
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: error.message,
        );
        return;
      case Success(data: final avatar):
        if (avatar.isNotModified) {
          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            avatarETag: avatar.eTag ?? state.avatarETag,
          );
          return;
        }
        final avatarBytes = avatar.bytes;
        if (avatarBytes != null && avatarBytes.isNotEmpty && userId > 0) {
          await _avatarCacheStore.saveForUser(
            userId: userId,
            bytes: avatarBytes,
            eTag: avatar.eTag,
          );
        }
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          avatarBytes: avatarBytes,
          avatarETag: avatar.eTag,
        );
        return;
    }
  }

  void setFullName(String value) {
    state = state.copyWith(fullName: value, errorMessage: null);
  }

  void setBirthDate(String value) {
    state = state.copyWith(birthDate: value, errorMessage: null);
  }

  void setHeightCm(String value) {
    state = state.copyWith(heightCm: value, errorMessage: null);
  }

  void setWeightKg(String value) {
    state = state.copyWith(weightKg: value, errorMessage: null);
  }

  void setWaistCm(String value) {
    state = state.copyWith(waistCm: value, errorMessage: null);
  }

  void setDiseaseHistoryInput(String value) {
    state = state.copyWith(diseaseHistoryInput: value, errorMessage: null);
  }

  void setGender(UserGender gender) {
    state = state.copyWith(gender: gender, errorMessage: null);
  }

  Future<String?> saveProfile() async {
    if (state.isSaving) return null;

    final birthDate = state.birthDate.trim();
    if (birthDate.isNotEmpty &&
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthDate)) {
      return _fail('出生日期格式应为 yyyy-MM-dd');
    }

    final heightCm = _parseOptionalDouble(state.heightCm, '身高');
    if (heightCm.$2 != null) return _fail(heightCm.$2!);

    final weightKg = _parseOptionalDouble(state.weightKg, '体重');
    if (weightKg.$2 != null) return _fail(weightKg.$2!);

    final waistCm = _parseOptionalDouble(state.waistCm, '腰围');
    if (waistCm.$2 != null) return _fail(waistCm.$2!);

    final diseaseHistory = _parseDiseaseHistory(state.diseaseHistoryInput);
    if (diseaseHistory.length > 50) {
      return _fail('疾病史最多可填写 50 项');
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final payload = UpsertUserBasicProfilePayload(
      fullName: state.fullName.trim().isEmpty ? null : state.fullName.trim(),
      gender: state.gender,
      birthDate: birthDate.isEmpty ? null : birthDate,
      heightCm: heightCm.$1,
      weightKg: weightKg.$1,
      waistCm: waistCm.$1,
      diseaseHistory: diseaseHistory,
    );

    final result = await _ref
        .read(updateBasicProfileUseCaseProvider)
        .execute(payload);

    switch (result) {
      case Failure(error: final error):
        state = state.copyWith(isSaving: false, errorMessage: error.message);
        return error.message;
      case Success(data: final profile):
        await _basicProfileCacheStore.saveForUser(profile);
        _applyProfileToState(profile, isSaving: false);
        return '基本资料已保存';
    }
  }

  Future<String?> pickAndUploadAvatar(ImageSource source) async {
    if (state.isUploadingAvatar) return null;

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;

    state = state.copyWith(isUploadingAvatar: true, errorMessage: null);

    File? processedFile;
    try {
      processedFile = await _avatarImageProcessor.processForUpload(pickedFile);
      if (processedFile == null) {
        state = state.copyWith(isUploadingAvatar: false);
        return null;
      }
      if (!processedFile.existsSync()) {
        return _failUploadingAvatar('图片处理失败，请重试');
      }
    } on Exception {
      return _failUploadingAvatar('图片处理失败，请重试');
    }

    final uploadResult = await _ref
        .read(uploadAvatarUseCaseProvider)
        .execute(processedFile);
    switch (uploadResult) {
      case Failure(error: final error):
        _deleteTempFileQuietly(processedFile);
        return _failUploadingAvatar(error.message);
      case Success():
        break;
    }
    _deleteTempFileQuietly(processedFile);

    final avatarResult = await _ref
        .read(getAvatarUseCaseProvider)
        .execute(ifNoneMatch: null);

    switch (avatarResult) {
      case Failure(error: final error):
        return _failUploadingAvatar(error.message);
      case Success(data: final avatar):
        final currentUserId = AppPrefs.sessionUserId.value;
        final avatarBytes = avatar.bytes;
        if (avatarBytes != null &&
            avatarBytes.isNotEmpty &&
            currentUserId > 0) {
          await _avatarCacheStore.saveForUser(
            userId: currentUserId,
            bytes: avatarBytes,
            eTag: avatar.eTag,
          );
        }
        state = state.copyWith(
          isUploadingAvatar: false,
          avatarBytes: avatarBytes ?? state.avatarBytes,
          avatarETag: avatar.eTag,
        );
        return '头像已更新';
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _fail(String message) {
    state = state.copyWith(errorMessage: message);
    return message;
  }

  String _failUploadingAvatar(String message) {
    state = state.copyWith(isUploadingAvatar: false, errorMessage: message);
    return message;
  }

  void _deleteTempFileQuietly(File file) {
    if (!file.existsSync()) return;
    try {
      file.deleteSync();
    } catch (_) {
      // Ignore temp file cleanup failure.
    }
  }

  (double?, String?) _parseOptionalDouble(String raw, String fieldName) {
    final text = raw.trim();
    if (text.isEmpty) return (null, null);

    final value = double.tryParse(text);
    if (value == null) {
      return (null, '$fieldName格式不正确');
    }

    return (value, null);
  }

  List<String> _parseDiseaseHistory(String input) {
    if (input.trim().isEmpty) return const <String>[];

    final tokens = input
        .split(RegExp(r'[\n,，、;；]+'))
        .map((it) => it.trim())
        .where((it) => it.isNotEmpty)
        .toList(growable: false);

    final result = <String>[];
    final dedup = <String>{};
    for (final token in tokens) {
      if (dedup.contains(token)) continue;
      dedup.add(token);
      result.add(token);
    }
    return result;
  }

  void _hydrateProfileInputs(UserBasicProfile profile) {
    state = state.copyWith(
      fullName: profile.fullName ?? '',
      birthDate: profile.birthDate ?? '',
      heightCm: _formatDouble(profile.heightCm),
      weightKg: _formatDouble(profile.weightKg),
      waistCm: _formatDouble(profile.waistCm),
      diseaseHistoryInput: profile.diseaseHistory.join('\n'),
      gender: profile.gender,
    );
  }

  void _applyProfileToState(UserBasicProfile profile, {bool? isSaving}) {
    state = state.copyWith(
      profile: profile,
      fullName: profile.fullName ?? '',
      birthDate: profile.birthDate ?? '',
      heightCm: _formatDouble(profile.heightCm),
      weightKg: _formatDouble(profile.weightKg),
      waistCm: _formatDouble(profile.waistCm),
      diseaseHistoryInput: profile.diseaseHistory.join('\n'),
      gender: profile.gender,
      isLoading: false,
      isRefreshing: false,
      isSaving: isSaving ?? state.isSaving,
      errorMessage: null,
    );
  }

  String _formatDouble(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    final fixed = value.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
