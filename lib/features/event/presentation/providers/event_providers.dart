import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/features/event/data/remote/event_api.dart';
import 'package:mindisle_client/features/event/data/repositories/event_repository_impl.dart';
import 'package:mindisle_client/features/event/domain/repositories/event_repository.dart';
import 'package:mindisle_client/features/event/domain/usecases/event_usecases.dart';

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

final updateDoctorBindingStatusUseCaseProvider =
    Provider<UpdateDoctorBindingStatusUseCase>((ref) {
      return UpdateDoctorBindingStatusUseCase(
        ref.watch(eventRepositoryProvider),
      );
    });
