import 'package:doctor/core/presentation/async_state.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';

typedef DoctorPatientState = AsyncState<DoctorPatientData>;

final class DoctorPatientData {
  const DoctorPatientData({
    this.items = const <DoctorPatient>[],
    this.query = const DoctorPatientQuery(),
    this.nextCursor,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
  });

  final List<DoctorPatient> items;
  final DoctorPatientQuery query;
  final String? nextCursor;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasLoaded;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  DoctorPatientData copyWith({
    List<DoctorPatient>? items,
    DoctorPatientQuery? query,
    Object? nextCursor = asyncStateNoChange,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasLoaded,
  }) {
    return DoctorPatientData(
      items: items ?? this.items,
      query: query ?? this.query,
      nextCursor: identical(nextCursor, asyncStateNoChange)
          ? this.nextCursor
          : nextCursor as String?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}
