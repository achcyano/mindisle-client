import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';

final class ScaleHistoryState {
  const ScaleHistoryState({
    this.initialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.items = const <ScaleHistoryItem>[],
    this.errorMessage,
  });

  final bool initialized;
  final bool isLoading;
  final bool isRefreshing;
  final List<ScaleHistoryItem> items;
  final String? errorMessage;

  ScaleHistoryState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isRefreshing,
    List<ScaleHistoryItem>? items,
    Object? errorMessage = _sentinel,
  }) {
    return ScaleHistoryState(
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
