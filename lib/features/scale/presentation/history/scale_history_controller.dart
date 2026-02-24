import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/history/scale_history_state.dart';
import 'package:mindisle_client/features/scale/presentation/providers/scale_providers.dart';

final scaleHistoryControllerProvider =
    StateNotifierProvider<ScaleHistoryController, ScaleHistoryState>((ref) {
      return ScaleHistoryController(ref);
    });

final class ScaleHistoryController extends StateNotifier<ScaleHistoryState> {
  ScaleHistoryController(this._ref) : super(const ScaleHistoryState());

  final Ref _ref;

  Future<void> initialize() async {
    if (state.initialized) return;
    await loadHistory();
  }

  Future<void> loadHistory({bool refresh = false}) async {
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

    final result = await _ref.read(fetchScaleHistoryUseCaseProvider).execute();
    switch (result) {
      case Failure<List<ScaleHistoryItem>>(error: final error):
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          errorMessage: error.message,
        );
        return;
      case Success<List<ScaleHistoryItem>>(data: final items):
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          items: items,
        );
        return;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
