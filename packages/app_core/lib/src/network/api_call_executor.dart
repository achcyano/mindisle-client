import 'package:dio/dio.dart';
import 'package:app_core/src/network/api_envelope.dart';
import 'package:app_core/src/network/error_mapper.dart';
import 'package:app_core/src/result/result.dart';

final class ApiCallExecutor {
  const ApiCallExecutor();

  Future<Result<T>> run<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Object? rawData) decodeData, {
    bool allowNullData = false,
    String nullDataMessage = '返回数据为空',
  }) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<T>.fromJson(json, decodeData);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(
            code: envelope.code,
            message: envelope.message,
          ),
        );
      }

      final data = envelope.data;
      if (data == null && !allowNullData) {
        return Failure(
          mapServerCodeToAppError(code: 50000, message: nullDataMessage),
        );
      }
      return Success(data as T);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }

  Future<Result<bool>> runNoData(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      final json = await request();
      final envelope = ApiEnvelope<Object?>.fromJson(json, (raw) => raw);
      if (!envelope.isSuccess) {
        return Failure(
          mapServerCodeToAppError(
            code: envelope.code,
            message: envelope.message,
          ),
        );
      }
      return const Success(true);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }
}
