import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/features/side_effect/domain/entities/side_effect_entities.dart';
import 'package:patient/features/side_effect/presentation/providers/side_effect_providers.dart';
import 'package:patient/features/side_effect/presentation/side_effect/side_effect_state.dart';

final sideEffectControllerProvider =
    StateNotifierProvider<SideEffectController, SideEffectState>((ref) {
  return SideEffectController(ref);
});

final class SideEffectController extends StateNotifier<SideEffectState> {
  SideEffectController(this._ref) : super(const SideEffectState());

  final Ref _ref;

  Future<void> initialize() async {
    if (state.initialized) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, initialized: true, errorMessage: null);

    final result = await _ref.read(fetchSideEffectsUseCaseProvider).execute(limit: 100);
    switch (result) {
      case Success<SideEffectListResult>(data: final data):
        state = state.copyWith(
          isLoading: false,
          items: data.items,
          errorMessage: null,
        );
      case Failure<SideEffectListResult>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  Future<String?> submit(CreateSideEffectPayload payload) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = await _ref.read(createSideEffectUseCaseProvider).execute(payload);
    switch (result) {
      case Success<SideEffectRecord>(data: final data):
        final updated = [data, ...state.items];
        state = state.copyWith(isSubmitting: false, items: updated);
        return null;
      case Failure<SideEffectRecord>(error: final error):
        state = state.copyWith(isSubmitting: false, errorMessage: error.message);
        return error.message;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
