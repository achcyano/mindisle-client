import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/list/scale_list_state.dart';
import 'package:mindisle_client/features/scale/presentation/providers/scale_providers.dart';

final scaleListControllerProvider =
    StateNotifierProvider<ScaleListController, ScaleListState>((ref) {
      return ScaleListController(ref);
    });

final class ScaleListController extends StateNotifier<ScaleListState> {
  ScaleListController(this._ref) : super(const ScaleListState());

  final Ref _ref;

  Future<void> initialize() async {
    if (state.initialized) return;
    await loadScales();
  }

  Future<void> loadScales({bool refresh = false}) async {
    if (refresh) {
      if (state.isRefreshing) return;
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      if (state.isLoading) return;
      state = state.copyWith(
        initialized: true,
        isLoading: true,
        errorMessage: null,
      );
    }

    final result = await _ref
        .read(fetchScalesUseCaseProvider)
        .execute(status: 'PUBLISHED');

    switch (result) {
      case Failure<List<ScaleSummary>>(error: final error):
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          errorMessage: error.message,
        );
        return;
      case Success<List<ScaleSummary>>(data: final scales):
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          items: scales,
        );
        return;
    }
  }

  Future<ScaleSession?> openScale(ScaleSummary scale) async {
    if (state.openingScaleId != null) return null;
    state = state.copyWith(openingScaleId: scale.scaleId, errorMessage: null);

    final result = await _ref
        .read(createOrResumeScaleSessionUseCaseProvider)
        .execute(scaleId: scale.scaleId);

    switch (result) {
      case Failure<ScaleCreateSessionResult>(error: final error):
        state = state.copyWith(
          openingScaleId: null,
          errorMessage: error.message,
        );
        return null;
      case Success<ScaleCreateSessionResult>(data: final data):
        state = state.copyWith(openingScaleId: null);
        return data.session;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
