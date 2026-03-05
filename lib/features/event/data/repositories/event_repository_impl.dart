import 'package:dio/dio.dart';
import 'package:mindisle_client/core/network/api_envelope.dart';
import 'package:mindisle_client/core/network/error_mapper.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/event/data/models/event_models.dart';
import 'package:mindisle_client/features/event/data/remote/event_api.dart';
import 'package:mindisle_client/features/event/domain/entities/event_entities.dart';
import 'package:mindisle_client/features/event/domain/repositories/event_repository.dart';

final class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._api);

  final EventApi _api;

  @override
  Future<Result<UserEventList>> fetchUserEvents() {
    return _run(_api.listUserEvents, _decodeEventList);
  }

  @override
  Future<Result<DoctorBindingStatus>> getDoctorBindingStatus() {
    return _run(_api.getDoctorBindingStatus, _decodeDoctorBindingStatus);
  }

  @override
  Future<Result<DoctorBindingStatus>> updateDoctorBindingStatus({
    required bool isBound,
  }) {
    return _run(
      () => _api.updateDoctorBindingStatus(isBound: isBound),
      _decodeDoctorBindingStatus,
    );
  }

  Future<Result<T>> _run<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Object? rawData) decodeData,
  ) async {
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
      if (data == null) {
        return Failure(
          mapServerCodeToAppError(
            code: 50000,
            message: '响应数据为空',
          ),
        );
      }
      return Success(data);
    } on DioException catch (e) {
      return Failure(mapDioExceptionToAppError(e));
    } catch (e) {
      return Failure(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }

  UserEventList _decodeEventList(Object? rawData) {
    if (rawData is Map) {
      return UserEventListDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('事件列表格式错误');
  }

  DoctorBindingStatus _decodeDoctorBindingStatus(Object? rawData) {
    if (rawData is Map) {
      return DoctorBindingStatusDto.fromJson(
        Map<String, dynamic>.from(rawData),
      ).toDomain();
    }
    throw const FormatException('医生绑定状态格式错误');
  }
}
