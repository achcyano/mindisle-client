const Object asyncStateNoChange = Object();

final class AsyncState<T> {
  const AsyncState({
    required this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  final T data;
  final bool isLoading;
  final String? errorMessage;

  AsyncState<T> copyWith({
    T? data,
    bool? isLoading,
    Object? errorMessage = asyncStateNoChange,
  }) {
    return AsyncState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, asyncStateNoChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
