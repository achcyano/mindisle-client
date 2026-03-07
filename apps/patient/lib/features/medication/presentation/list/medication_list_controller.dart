import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/features/medication/domain/entities/medication_entities.dart';
import 'package:patient/features/medication/presentation/list/medication_list_state.dart';
import 'package:patient/features/medication/presentation/providers/medication_providers.dart';

final medicationListControllerProvider =
    StateNotifierProvider<MedicationListController, MedicationListState>((ref) {
      return MedicationListController(ref);
    });

final class MedicationListController extends StateNotifier<MedicationListState> {
  MedicationListController(this._ref) : super(const MedicationListState());

  final Ref _ref;

  Future<void> initialize() async {
    if (state.initialized) return;
    await loadMedications();
  }

  Future<void> refresh() {
    return loadMedications(refresh: true);
  }

  Future<void> loadMedications({bool refresh = false}) async {
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
        .read(fetchMedicationsUseCaseProvider)
        .execute(limit: 200, onlyActive: false);

    switch (result) {
      case Failure<MedicationListResult>(error: final error):
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          errorMessage: error.message,
        );
        return;
      case Success<MedicationListResult>(data: final data):
        final items = data.items.toList(growable: false)
          ..sort((a, b) => b.medicationId.compareTo(a.medicationId));

        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          items: items,
          errorMessage: null,
        );
        return;
    }
  }

  Future<String?> deleteMedication(int medicationId) async {
    if (state.deletingMedicationId != null) return null;

    state = state.copyWith(
      deletingMedicationId: medicationId,
      errorMessage: null,
    );

    final result = await _ref
        .read(deleteMedicationUseCaseProvider)
        .execute(medicationId: medicationId);

    switch (result) {
      case Failure<bool>(error: final error):
        state = state.copyWith(
          deletingMedicationId: null,
          errorMessage: error.message,
        );
        return error.message;
      case Success<bool>():
        final nextItems = state.items
            .where((item) => item.medicationId != medicationId)
            .toList(growable: false);
        state = state.copyWith(
          deletingMedicationId: null,
          items: nextItems,
          errorMessage: null,
        );
        return '已删除';
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
