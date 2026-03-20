import 'package:app_core/app_core.dart';
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

  Future<void> refreshBindingCode() async {
    if (state.isLoading) return;

    final preserveErrorWhileLoading = state.data.latestCode == null;
    state = state.copyWith(
      data: state.data.copyWith(latestCode: null),
      isLoading: true,
      errorMessage: preserveErrorWhileLoading ? state.errorMessage : null,
    );

    final result = await _ref
        .read(createDoctorBindingCodeUseCaseProvider)
        .execute();
    switch (result) {
      case Success<DoctorBindingCode>(data: final code):
        final validationMessage = _validateBindingCode(code);
        state = state.copyWith(
          data: state.data.copyWith(
            latestCode: validationMessage == null ? code : null,
          ),
          isLoading: false,
          errorMessage: validationMessage,
        );
      case Failure<DoctorBindingCode>(error: final error):
        state = state.copyWith(
          data: state.data.copyWith(latestCode: null),
          isLoading: false,
          errorMessage: error.message,
        );
    }
  }

  String? _validateBindingCode(DoctorBindingCode code) {
    if (code.code.trim().isEmpty) {
      return '绑定码数据不完整，请稍后重试';
    }
    return null;
  }
}
