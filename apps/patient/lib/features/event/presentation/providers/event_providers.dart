import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/providers/app_providers.dart';
import 'package:patient/features/event/data/remote/event_api.dart';
import 'package:patient/features/event/data/repositories/event_repository_impl.dart';
import 'package:patient/features/event/domain/repositories/event_repository.dart';
import 'package:patient/features/event/domain/usecases/event_usecases.dart';

final eventApiProvider = Provider<EventApi>((ref) {
  return EventApi(ref.watch(appDioProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(eventApiProvider));
});

final fetchUserEventsUseCaseProvider = Provider<FetchUserEventsUseCase>((ref) {
  return FetchUserEventsUseCase(ref.watch(eventRepositoryProvider));
});

final getDoctorBindingStatusUseCaseProvider =
    Provider<GetDoctorBindingStatusUseCase>((ref) {
  return GetDoctorBindingStatusUseCase(ref.watch(eventRepositoryProvider));
});

final bindDoctorUseCaseProvider = Provider<BindDoctorUseCase>((ref) {
  return BindDoctorUseCase(ref.watch(eventRepositoryProvider));
});

final unbindDoctorUseCaseProvider = Provider<UnbindDoctorUseCase>((ref) {
  return UnbindDoctorUseCase(ref.watch(eventRepositoryProvider));
});

final fetchDoctorBindingHistoryUseCaseProvider =
    Provider<FetchDoctorBindingHistoryUseCase>((ref) {
  return FetchDoctorBindingHistoryUseCase(ref.watch(eventRepositoryProvider));
});
