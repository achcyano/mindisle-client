import 'package:flutter/foundation.dart';
import 'package:mindisle_client/features/user/domain/entities/user_basic_profile.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';

@immutable
final class ProfileState {
  const ProfileState({
    this.initialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.profile,
    this.avatarBytes,
    this.avatarETag,
    this.errorMessage,
    this.phone = '',
    this.fullName = '',
    this.birthDate = '',
    this.heightCm = '',
    this.weightKg = '',
    this.waistCm = '',
    this.diseaseHistoryInput = '',
    this.gender = UserGender.unknown,
  });

  final bool initialized;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSaving;
  final bool isUploadingAvatar;
  final UserBasicProfile? profile;
  final Uint8List? avatarBytes;
  final String? avatarETag;
  final String? errorMessage;

  final String phone;
  final String fullName;
  final String birthDate;
  final String heightCm;
  final String weightKg;
  final String waistCm;
  final String diseaseHistoryInput;
  final UserGender gender;

  ProfileState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSaving,
    bool? isUploadingAvatar,
    Object? profile = _sentinel,
    Object? avatarBytes = _sentinel,
    Object? avatarETag = _sentinel,
    Object? errorMessage = _sentinel,
    String? phone,
    String? fullName,
    String? birthDate,
    String? heightCm,
    String? weightKg,
    String? waistCm,
    String? diseaseHistoryInput,
    UserGender? gender,
  }) {
    return ProfileState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSaving: isSaving ?? this.isSaving,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      profile: identical(profile, _sentinel)
          ? this.profile
          : profile as UserBasicProfile?,
      avatarBytes: identical(avatarBytes, _sentinel)
          ? this.avatarBytes
          : avatarBytes as Uint8List?,
      avatarETag: identical(avatarETag, _sentinel)
          ? this.avatarETag
          : avatarETag as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      waistCm: waistCm ?? this.waistCm,
      diseaseHistoryInput: diseaseHistoryInput ?? this.diseaseHistoryInput,
      gender: gender ?? this.gender,
    );
  }
}

const Object _sentinel = Object();
