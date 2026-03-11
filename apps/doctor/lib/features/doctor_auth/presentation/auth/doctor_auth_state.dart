import 'package:flutter/foundation.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';

@immutable
final class DoctorAuthState {
  const DoctorAuthState({this.session, this.isInitialized = false});

  final DoctorAuthSessionResult? session;
  final bool isInitialized;

  DoctorAuthState copyWith({Object? session = _sentinel, bool? isInitialized}) {
    return DoctorAuthState(
      session: identical(session, _sentinel)
          ? this.session
          : session as DoctorAuthSessionResult?,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  static const _sentinel = Object();
}
