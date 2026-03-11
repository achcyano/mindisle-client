import 'package:app_core/app_core.dart';
import 'package:doctor/core/presentation/async_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AsyncController<T> extends StateNotifier<AsyncState<T>> {
  AsyncController(super.state);

  Future<String?> runAction<R>({
    required Future<Result<R>> Function() request,
    required T Function(T current, R data) onSuccess,
    bool withLoading = true,
    bool clearErrorOnStart = true,
    String? successMessage,
    String? Function(R data)? successMessageBuilder,
  }) async {
    if (withLoading) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: clearErrorOnStart ? null : state.errorMessage,
      );
    } else if (clearErrorOnStart) {
      state = state.copyWith(errorMessage: null);
    }

    final result = await request();
    return result.when(
      success: (data) {
        state = state.copyWith(
          data: onSuccess(state.data, data),
          isLoading: false,
          errorMessage: null,
        );
        return successMessageBuilder?.call(data) ?? successMessage;
      },
      failure: (error) {
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return error.message;
      },
    );
  }
}
