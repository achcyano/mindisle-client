import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';

typedef DoctorPatientState = AsyncState<DoctorPatientData>;

final class DoctorPatientData {
  const DoctorPatientData({this.items = const <DoctorPatient>[]});

  final List<DoctorPatient> items;

  DoctorPatientData copyWith({List<DoctorPatient>? items}) {
    return DoctorPatientData(items: items ?? this.items);
  }
}
