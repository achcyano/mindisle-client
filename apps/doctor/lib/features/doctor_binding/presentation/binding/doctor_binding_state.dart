import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';

typedef DoctorBindingState = AsyncState<DoctorBindingData>;

final class DoctorBindingData {
  const DoctorBindingData({
    this.latestCode,
    this.history = const <DoctorBindingHistoryItem>[],
  });

  final DoctorBindingCode? latestCode;
  final List<DoctorBindingHistoryItem> history;

  DoctorBindingData copyWith({
    Object? latestCode = asyncStateNoChange,
    List<DoctorBindingHistoryItem>? history,
  }) {
    return DoctorBindingData(
      latestCode: identical(latestCode, asyncStateNoChange)
          ? this.latestCode
          : latestCode as DoctorBindingCode?,
      history: history ?? this.history,
    );
  }
}
