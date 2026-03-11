import 'package:doctor/core/presentation/async_state.dart';
import 'package:models/models.dart';

typedef DoctorMedicationState = AsyncState<DoctorMedicationData>;

final class DoctorMedicationData {
  const DoctorMedicationData({this.items = const <MedicationRecord>[]});

  final List<MedicationRecord> items;

  DoctorMedicationData copyWith({List<MedicationRecord>? items}) {
    return DoctorMedicationData(items: items ?? this.items);
  }
}
