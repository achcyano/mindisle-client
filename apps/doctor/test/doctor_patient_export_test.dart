import 'dart:convert';

import 'package:app_core/app_core.dart';
import 'package:dio/dio.dart';
import 'package:doctor/features/doctor_patient/data/remote/doctor_patient_api.dart';
import 'package:doctor/features/doctor_patient/data/repositories/doctor_patient_repository_impl.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('doctor patient export filename parsing', () {
    test('parses plain filename', () {
      final fileName = parseExportFileNameFromContentDisposition(
        'attachment; filename="patients-export.zip"',
      );

      expect(fileName, 'patients-export.zip');
    });

    test('parses utf8 filename*', () {
      final fileName = parseExportFileNameFromContentDisposition(
        "attachment; filename*=UTF-8''doctor-%E5%AF%BC%E5%87%BA.zip",
      );

      expect(fileName, 'doctor-导出.zip');
    });

    test('returns null when header is missing', () {
      final fileName = parseExportFileNameFromContentDisposition(null);

      expect(fileName, isNull);
    });
  });

  group('DoctorPatientRepositoryImpl.exportPatients', () {
    test('returns export file on success', () async {
      final repository = _buildRepository((options, handler) {
        handler.resolve(
          Response<List<int>>(
            requestOptions: options,
            data: utf8.encode('PK\x03\x04'),
            statusCode: 200,
            headers: Headers.fromMap({
              'content-disposition': [
                'attachment; filename="doctor-export.zip"',
              ],
            }),
          ),
        );
      });

      final result = await repository.exportPatients();

      expect(result, isA<Success<DoctorPatientExportFile>>());
      final file = (result as Success<DoctorPatientExportFile>).data;
      expect(file.fileName, 'doctor-export.zip');
      expect(file.mimeType, 'application/zip');
      expect(file.bytes, isNotEmpty);
    });

    test('maps bytes body error to localized app error', () async {
      final repository = _buildRepository((options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<List<int>>(
              requestOptions: options,
              statusCode: 403,
              data: utf8.encode('{"code":40340,"message":"forbidden"}'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      });

      final result = await repository.exportPatients();

      expect(result, isA<Failure<DoctorPatientExportFile>>());
      final error = (result as Failure<DoctorPatientExportFile>).error;
      expect(error.code, 40340);
      expect(error.message, '无权限访问该医生资源');
    });

    test('returns failure when file is empty', () async {
      final repository = _buildRepository((options, handler) {
        handler.resolve(
          Response<List<int>>(
            requestOptions: options,
            data: const <int>[],
            statusCode: 200,
          ),
        );
      });

      final result = await repository.exportPatients();

      expect(result, isA<Failure<DoctorPatientExportFile>>());
      final error = (result as Failure<DoctorPatientExportFile>).error;
      expect(error.message, '导出文件为空，请稍后重试');
    });
  });
}

DoctorPatientRepositoryImpl _buildRepository(
  void Function(RequestOptions options, RequestInterceptorHandler handler)
  onRequest,
) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options, handler);
      },
    ),
  );
  return DoctorPatientRepositoryImpl(DoctorPatientApi(dio));
}
