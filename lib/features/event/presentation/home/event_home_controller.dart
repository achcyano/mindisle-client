import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/event/domain/entities/event_entities.dart';
import 'package:mindisle_client/features/event/presentation/home/event_home_state.dart';
import 'package:mindisle_client/features/event/presentation/providers/event_providers.dart';

final eventHomeControllerProvider =
    StateNotifierProvider<EventHomeController, EventHomeState>((ref) {
      return EventHomeController(ref);
    });

final class EventHomeController extends StateNotifier<EventHomeState> {
  EventHomeController(this._ref) : super(const EventHomeState());

  final Ref _ref;

  Future<void> initialize() async {
    if (state.initialized) return;
    await loadEvents();
  }

  Future<void> refresh() {
    return loadEvents(refresh: true);
  }

  Future<void> loadEvents({bool refresh = false}) async {
    if (refresh) {
      if (state.isRefreshing) return;
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      if (state.isLoading) return;
      state = state.copyWith(
        initialized: true,
        isLoading: true,
        errorMessage: null,
      );
    }

    final result = await _ref.read(fetchUserEventsUseCaseProvider).execute();

    switch (result) {
      case Failure<UserEventList>(error: final error):
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          errorMessage: error.message,
        );
        return;
      case Success<UserEventList>(data: final data):
        final sorted = _sortEvents(data.items);
        final visible = _filterVisibleEvents(sorted);
        state = state.copyWith(
          initialized: true,
          isLoading: false,
          isRefreshing: false,
          errorMessage: null,
          items: _collapseScaleEvents(visible),
        );
        return;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  List<UserEventItem> _sortEvents(List<UserEventItem> items) {
    final sorted = items.toList(growable: false);
    sorted.sort((a, b) {
      final left = a.dueAt;
      final right = b.dueAt;
      if (left == null && right == null) {
        return a.eventName.compareTo(b.eventName);
      }
      if (left == null) return 1;
      if (right == null) return -1;
      final dueCompare = left.compareTo(right);
      if (dueCompare != 0) return dueCompare;
      return a.eventName.compareTo(b.eventName);
    });
    return sorted;
  }

  List<UserEventItem> _filterVisibleEvents(List<UserEventItem> items) {
    final now = DateTime.now().toUtc();
    return items.where((item) {
      final dueAt = item.dueAt;
      if (dueAt == null) return true;
      return !dueAt.toUtc().isAfter(now);
    }).toList(growable: false);
  }

  List<UserEventItem> _collapseScaleEvents(List<UserEventItem> items) {
    final selectedContinueEvent = _pickBestContinueScaleEvent(items);
    UserEventItem? selectedScaleEvent = selectedContinueEvent;

    if (selectedScaleEvent == null) {
      for (final item in items) {
        if (item.eventType == UserEventType.openScale) {
          selectedScaleEvent = item;
          break;
        }
      }
    }

    if (selectedScaleEvent == null) return items;

    final result = <UserEventItem>[];
    var insertedScaleEvent = false;
    for (final item in items) {
      if (_isScaleEvent(item.eventType)) {
        if (!insertedScaleEvent) {
          result.add(selectedScaleEvent);
          insertedScaleEvent = true;
        }
        continue;
      }
      result.add(item);
    }
    return result;
  }

  UserEventItem? _pickBestContinueScaleEvent(List<UserEventItem> items) {
    UserEventItem? best;
    var bestProgress = -1;

    for (final item in items) {
      if (item.eventType != UserEventType.continueScaleSession) continue;

      final progress = item.progress ?? -1;
      if (best == null || progress > bestProgress) {
        best = item;
        bestProgress = progress;
      }
    }

    return best;
  }

  bool _isScaleEvent(UserEventType type) {
    return type == UserEventType.openScale ||
        type == UserEventType.continueScaleSession;
  }
}
