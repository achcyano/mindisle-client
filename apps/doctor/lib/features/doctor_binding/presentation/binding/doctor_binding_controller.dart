import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';
import 'package:doctor/features/doctor_binding/presentation/binding/doctor_binding_state.dart';
import 'package:doctor/features/doctor_binding/presentation/providers/doctor_binding_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorBindingControllerProvider =
    StateNotifierProvider<DoctorBindingController, DoctorBindingState>((ref) {
      return DoctorBindingController(ref);
    });

final class DoctorBindingController extends AsyncController<DoctorBindingData> {
  DoctorBindingController(this._ref)
    : super(const AsyncState<DoctorBindingData>(data: DoctorBindingData()));

  final Ref _ref;

  Future<void> refreshHistory() async {
    await runAction<DoctorBindingHistoryResult>(
      request: () => _ref
          .read(fetchDoctorBindingHistoryUseCaseProvider)
          .execute(limit: 50),
      onSuccess: (current, data) => current.copyWith(history: data.items),
    );
  }

  Future<String?> createCode() {
    return runAction<DoctorBindingCode>(
      request: () =>
          _ref.read(createDoctorBindingCodeUseCaseProvider).execute(),
      onSuccess: (current, code) => current.copyWith(latestCode: code),
    );
  }
}
