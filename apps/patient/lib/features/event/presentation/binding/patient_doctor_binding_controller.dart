import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/features/event/presentation/binding/patient_doctor_binding_state.dart';
import 'package:patient/features/event/presentation/providers/event_providers.dart';

final patientDoctorBindingControllerProvider =
    StateNotifierProvider<
      PatientDoctorBindingController,
      PatientDoctorBindingState
    >((ref) {
      return PatientDoctorBindingController(ref);
    });

final class PatientDoctorBindingController
    extends StateNotifier<PatientDoctorBindingState> {
  PatientDoctorBindingController(this._ref)
    : super(const PatientDoctorBindingState());

  final Ref _ref;
  static final RegExp _bindingCodeRegExp = RegExp(r'^\d{5}$');

  Future<void> initialize({bool refresh = false}) async {
    if (state.initialized && !refresh) return;
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    if (state.isLoading) return;

    state = state.copyWith(
      initialized: true,
      isLoading: true,
      errorMessage: null,
    );

    final result = await _ref
        .read(getDoctorBindingStatusUseCaseProvider)
        .execute();
    switch (result) {
      case Success<DoctorBindingStatus>(data: final data):
        state = state.copyWith(
          isLoading: false,
          status: data,
          errorMessage: null,
          inputCode: data.isBound ? '' : state.inputCode,
        );
      case Failure<DoctorBindingStatus>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  void setMode(PatientDoctorBindingMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode, errorMessage: null);
  }

  void inputDigit(String digit) {
    if (state.isBusy || state.mode != PatientDoctorBindingMode.manual) return;
    if (!RegExp(r'^\d$').hasMatch(digit)) return;
    if (state.inputCode.length >= 5) return;
    state = state.copyWith(
      inputCode: '${state.inputCode}$digit',
      errorMessage: null,
    );
  }

  void deleteDigit() {
    if (state.isBusy || state.mode != PatientDoctorBindingMode.manual) return;
    if (state.inputCode.isEmpty) return;
    state = state.copyWith(
      inputCode: state.inputCode.substring(0, state.inputCode.length - 1),
      errorMessage: null,
    );
  }

  void clearInput() {
    if (state.inputCode.isEmpty) return;
    state = state.copyWith(inputCode: '', errorMessage: null);
  }

  Future<String?> submitInputCode() {
    return _submitBindingCode(state.inputCode.trim());
  }

  Future<String?> submitScannedPayload(String rawValue) {
    final normalized = rawValue.trim();
    if (!_bindingCodeRegExp.hasMatch(normalized)) {
      return Future.value('二维码中未识别到有效的 5 位绑定码');
    }
    return _submitBindingCode(normalized);
  }

  Future<String?> unbind() async {
    if (state.isBusy) return null;

    state = state.copyWith(isUnbinding: true, errorMessage: null);
    final result = await _ref.read(unbindDoctorUseCaseProvider).execute();
    switch (result) {
      case Success<DoctorBindingStatus>(data: final data):
        state = state.copyWith(
          isUnbinding: false,
          status: data,
          inputCode: '',
          mode: PatientDoctorBindingMode.manual,
          errorMessage: null,
        );
        return '已解除医生绑定';
      case Failure<DoctorBindingStatus>(error: final error):
        state = state.copyWith(isUnbinding: false, errorMessage: error.message);
        return error.message;
    }
  }

  Future<String?> _submitBindingCode(String code) async {
    if (state.isBusy) return null;
    if (!_bindingCodeRegExp.hasMatch(code)) {
      state = state.copyWith(errorMessage: '请输入 5 位数字绑定码');
      return '请输入 5 位数字绑定码';
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref
        .read(bindDoctorUseCaseProvider)
        .execute(bindingCode: code);
    switch (result) {
      case Success<DoctorBindingStatus>(data: final data):
        state = state.copyWith(
          isSubmitting: false,
          status: data,
          inputCode: '',
          mode: PatientDoctorBindingMode.manual,
          errorMessage: null,
        );
        return '绑定成功';
      case Failure<DoctorBindingStatus>(error: final error):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        );
        return error.message;
    }
  }
}
