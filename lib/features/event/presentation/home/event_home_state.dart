import 'package:mindisle_client/features/event/domain/entities/event_entities.dart';

final class EventHomeState {
  const EventHomeState({
    this.initialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.items = const <UserEventItem>[],
    this.errorMessage,
  });

  final bool initialized;
  final bool isLoading;
  final bool isRefreshing;
  final List<UserEventItem> items;
  final String? errorMessage;

  EventHomeState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isRefreshing,
    List<UserEventItem>? items,
    Object? errorMessage = _sentinel,
  }) {
    return EventHomeState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      items: items ?? this.items,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
