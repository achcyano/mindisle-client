import 'package:patient/features/side_effect/domain/entities/side_effect_entities.dart';

final class SideEffectState {
  const SideEffectState({
    this.initialized = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.items = const <SideEffectRecord>[],
    this.errorMessage,
  });

  final bool initialized;
  final bool isLoading;
  final bool isSubmitting;
  final List<SideEffectRecord> items;
  final String? errorMessage;

  SideEffectState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isSubmitting,
    List<SideEffectRecord>? items,
    Object? errorMessage = _sentinel,
  }) {
    return SideEffectState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      items: items ?? this.items,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
