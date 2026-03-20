import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';

typedef DoctorBindingState = AsyncState<DoctorBindingData>;

final class DoctorBindingData {
  const DoctorBindingData({this.latestCode});

  final DoctorBindingCode? latestCode;

  DoctorBindingData copyWith({Object? latestCode = asyncStateNoChange}) {
    return DoctorBindingData(
      latestCode: identical(latestCode, asyncStateNoChange)
          ? this.latestCode
          : latestCode as DoctorBindingCode?,
    );
  }
}
