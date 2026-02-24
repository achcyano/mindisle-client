import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';

final class ScaleListState {
  const ScaleListState({
    this.initialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.items = const <ScaleSummary>[],
    this.openingScaleId,
    this.errorMessage,
  });

  final bool initialized;
  final bool isLoading;
  final bool isRefreshing;
  final List<ScaleSummary> items;
  final int? openingScaleId;
  final String? errorMessage;

  ScaleListState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isRefreshing,
    List<ScaleSummary>? items,
    Object? openingScaleId = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return ScaleListState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      items: items ?? this.items,
      openingScaleId: identical(openingScaleId, _sentinel)
          ? this.openingScaleId
          : openingScaleId as int?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
