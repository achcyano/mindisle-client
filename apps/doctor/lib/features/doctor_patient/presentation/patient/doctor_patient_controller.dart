import 'package:doctor/core/presentation/async_controller.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_state.dart';
import 'package:doctor/features/doctor_patient/presentation/providers/doctor_patient_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorPatientControllerProvider =
    StateNotifierProvider<DoctorPatientController, DoctorPatientState>((ref) {
      return DoctorPatientController(ref);
    });

final class DoctorPatientController extends AsyncController<DoctorPatientData> {
  DoctorPatientController(this._ref)
    : super(const AsyncState<DoctorPatientData>(data: DoctorPatientData()));

  final Ref _ref;

  Future<void> refresh({String? keyword, bool? abnormalOnly}) async {
    await runAction<DoctorPatientListResult>(
      request: () => _ref
          .read(fetchDoctorPatientsUseCaseProvider)
          .execute(limit: 50, keyword: keyword, abnormalOnly: abnormalOnly),
      onSuccess: (current, data) => current.copyWith(items: data.items),
    );
  }

  Future<String?> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) {
    return runAction<DoctorPatientGrouping>(
      request: () => _ref
          .read(updateDoctorPatientGroupingUseCaseProvider)
          .execute(patientUserId: patientUserId, payload: payload),
      onSuccess: (current, _) => current,
      withLoading: false,
    );
  }
}
