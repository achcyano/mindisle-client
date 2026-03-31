import 'dart:convert';

import 'package:app_core/app_core.dart';
import 'package:dio/dio.dart';
import 'package:doctor/features/doctor_patient/data/models/doctor_patient_models.dart';
import 'package:doctor/features/doctor_patient/data/remote/doctor_patient_api.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/domain/repositories/doctor_patient_repository.dart';

final class DoctorPatientRepositoryImpl implements DoctorPatientRepository {
  DoctorPatientRepositoryImpl(
    this._api, {
    ApiCallExecutor executor = const ApiCallExecutor(),
  }) : _executor = executor;

  final DoctorPatientApi _api;
  final ApiCallExecutor _executor;

  @override
  Future<Result<DoctorPatientListResult>> fetchPatients({
    required DoctorPatientQuery query,
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.fetchPatients(query: query, limit: limit, cursor: cursor),
      decodeDoctorPatientList,
    );
  }

  @override
  Future<Result<DoctorPatientGrouping>> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) {
    return _executor.run(
      () => _api.updateGrouping(patientUserId: patientUserId, payload: payload),
      decodeDoctorPatientGrouping,
    );
  }

  @override
  Future<Result<List<DoctorPatientGroupingHistoryItem>>> fetchGroupingHistory({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) {
    return _executor.run(
      () => _api.fetchGroupingHistory(
        patientUserId: patientUserId,
        limit: limit,
        cursor: cursor,
      ),
      decodeDoctorPatientGroupingHistory,
    );
  }

  @override
  Future<Result<List<DoctorPatientGroupOption>>> fetchPatientGroups() {
    return _executor.run(
      _api.fetchPatientGroups,
      decodeDoctorPatientGroupOptions,
    );
  }

  @override
  Future<Result<DoctorPatientGroupOption>> createPatientGroup({
    required String severityGroup,
  }) {
    return _executor.run(
      () => _api.createPatientGroup(severityGroup: severityGroup),
      decodeDoctorPatientGroupOption,
    );
  }

  @override
  Future<Result<DoctorPatientDiagnosisUpdateResult>> updateDiagnosis({
    required int patientUserId,
    required DoctorPatientDiagnosisUpdatePayload payload,
  }) {
    return _executor.run(
      () =>
          _api.updateDiagnosis(patientUserId: patientUserId, payload: payload),
      decodeDoctorPatientDiagnosisUpdateResult,
    );
  }

  @override
  Future<Result<DoctorPatientProfile>> fetchPatientProfile({
    required int patientUserId,
  }) {
    return _executor.run(
      () => _api.fetchPatientProfile(patientUserId: patientUserId),
      decodeDoctorPatientProfile,
    );
  }

  @override
  Future<Result<DoctorPatientExportFile>> exportPatients() async {
    try {
      final response = await _api.exportPatients();
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return const Failure<DoctorPatientExportFile>(
          AppError(type: AppErrorType.server, message: '导出文件为空，请稍后重试'),
        );
      }

      final contentDisposition = response.headers.value('content-disposition');
      final fileName =
          parseExportFileNameFromContentDisposition(contentDisposition) ??
          _fallbackExportFileName();

      return Success<DoctorPatientExportFile>(
        DoctorPatientExportFile(bytes: bytes, fileName: fileName),
      );
    } on DioException catch (e) {
      return Failure<DoctorPatientExportFile>(mapExportPatientsDioException(e));
    } catch (e) {
      return Failure<DoctorPatientExportFile>(
        mapServerCodeToAppError(code: 50000, message: e.toString()),
      );
    }
  }
}

AppError mapExportPatientsDioException(DioException exception) {
  final response = exception.response;
  final data = response?.data;
  if (data is List<int> && data.isNotEmpty) {
    try {
      final map = jsonDecode(utf8.decode(data));
      if (map is Map<String, dynamic> || map is Map) {
        final normalized = map is Map<String, dynamic>
            ? map
            : Map<String, dynamic>.from(map as Map);
        final code = (normalized['code'] as num?)?.toInt();
        final message = (normalized['message'] as String?) ?? '';
        if (code != null) {
          return mapServerCodeToAppError(
            code: code,
            message: message,
            statusCode: response?.statusCode,
          );
        }
      }
    } catch (_) {}
  }
  return mapDioExceptionToAppError(exception);
}

String? parseExportFileNameFromContentDisposition(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final utf8Match = RegExp(
    r'filename\*=([^;]+)',
    caseSensitive: false,
  ).firstMatch(value);
  if (utf8Match != null) {
    final raw = _trimQuotes(utf8Match.group(1)?.trim() ?? '');
    final splitIndex = raw.indexOf("''");
    final encodedName = splitIndex >= 0 ? raw.substring(splitIndex + 2) : raw;
    final decoded = Uri.decodeComponent(encodedName).trim();
    if (decoded.isNotEmpty) return _sanitizeFileName(decoded);
  }

  final plainMatch = RegExp(
    r'filename=("([^"]+)"|[^;]+)',
    caseSensitive: false,
  ).firstMatch(value);
  if (plainMatch != null) {
    final raw = plainMatch.group(2) ?? plainMatch.group(1) ?? '';
    final fileName = _trimQuotes(raw.trim());
    if (fileName.isNotEmpty) return _sanitizeFileName(fileName);
  }
  return null;
}

String _trimQuotes(String value) {
  if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

String _sanitizeFileName(String value) {
  final sanitized = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  if (sanitized.isEmpty) return _fallbackExportFileName();
  return sanitized.endsWith('.zip') ? sanitized : '$sanitized.zip';
}

String _fallbackExportFileName([DateTime? time]) {
  final now = time ?? DateTime.now();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final timestamp =
      '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}'
      '${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}';
  return 'doctor-patients-export-$timestamp.zip';
}
