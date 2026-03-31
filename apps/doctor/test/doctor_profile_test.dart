import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/domain/repositories/doctor_auth_repository.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/domain/repositories/doctor_patient_repository.dart';
import 'package:doctor/features/doctor_patient/presentation/providers/doctor_patient_providers.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/domain/repositories/doctor_profile_repository.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_controller.dart';
import 'package:doctor/features/doctor_profile/presentation/providers/doctor_profile_providers.dart';
import 'package:doctor/view/pages/auth/reset_password_page.dart';
import 'package:doctor/view/pages/me/me_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoctorProfileController', () {
    test('updateProfile updates the current profile', () async {
      final repository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院'),
      );
      final container = ProviderContainer(
        overrides: [
          doctorProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(doctorProfileControllerProvider.notifier).refresh();
      await container
          .read(doctorProfileControllerProvider.notifier)
          .updateProfile(
            const DoctorProfileUpdatePayload(fullName: '李医生', hospital: '华山医院'),
          );

      final state = container.read(doctorProfileControllerProvider);
      expect(state.data.profile?.fullName, '李医生');
      expect(state.data.profile?.hospital, '华山医院');
    });

    test('updateThresholds still updates threshold state', () async {
      final repository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院'),
      );
      final container = ProviderContainer(
        overrides: [
          doctorProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(doctorProfileControllerProvider.notifier).refresh();
      await container
          .read(doctorProfileControllerProvider.notifier)
          .updateThresholds(
            const DoctorThresholds(phq9Threshold: 12, gad7Threshold: 8),
          );

      final state = container.read(doctorProfileControllerProvider);
      expect(state.data.thresholds?.phq9Threshold, 12);
      expect(state.data.thresholds?.gad7Threshold, 8);
    });
  });

  group('Doctor profile editing flow', () {
    testWidgets('prefills fields and blocks back/FAB when values are empty', (
      tester,
    ) async {
      final repository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院'),
      );

      await _pumpMePage(tester, repository: repository);
      await tester.pumpAndSettle();

      expect(find.text('张医生'), findsAtLeastNWidgets(1));
      await tester.tap(find.text('编辑资料'));
      await tester.pumpAndSettle();

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].controller?.text, '张医生');
      expect(fields[1].controller?.text, '协和医院');

      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(repository.updateProfileCallCount, 0);
      expect(find.text('编辑资料'), findsOneWidget);
      expect(find.text('请输入姓名'), findsAtLeastNWidgets(1));

      await tester.enterText(find.byType(TextField).at(0), '张医生');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(repository.updateProfileCallCount, 0);
      expect(find.text('编辑资料'), findsOneWidget);
      expect(find.text('请输入医院'), findsAtLeastNWidgets(1));
    });

    testWidgets('saving profile updates me page immediately', (tester) async {
      final repository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院'),
      );

      await _pumpMePage(tester, repository: repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('编辑资料'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '李医生');
      await tester.enterText(find.byType(TextField).at(1), '华山医院');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.updateProfileCallCount, 1);
      expect(find.text('编辑资料'), findsOneWidget);
      expect(find.text('李医生'), findsAtLeastNWidgets(1));
      expect(find.text('华山医院'), findsAtLeastNWidgets(1));
    });
  });

  group('Doctor reset password entry', () {
    testWidgets('navigates to reset password page when phone exists', (
      tester,
    ) async {
      final profileRepository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院'),
      );

      await _pumpMePage(
        tester,
        repository: profileRepository,
        authRepository: _FakeDoctorAuthRepository(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(DoctorResetPasswordPage), findsOneWidget);
      expect(find.text('验证码已发送'), findsOneWidget);
    });

    testWidgets('shows message and stays on me page when phone is empty', (
      tester,
    ) async {
      final profileRepository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院', phone: ''),
      );

      await _pumpMePage(
        tester,
        repository: profileRepository,
        authRepository: _FakeDoctorAuthRepository(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(DoctorResetPasswordPage), findsNothing);
      expect(find.text('未绑定手机号，暂时无法修改密码'), findsOneWidget);
    });
  });

  group('Doctor export patients entry', () {
    testWidgets('shows export tile and opens success dialog after export', (
      tester,
    ) async {
      final profileRepository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院'),
      );
      final patientRepository = _FakeDoctorPatientRepository(
        onExport: () async => const Success<DoctorPatientExportFile>(
          DoctorPatientExportFile(bytes: <int>[1, 2, 3], fileName: 'demo.zip'),
        ),
      );

      await _pumpMePage(
        tester,
        repository: profileRepository,
        patientRepository: patientRepository,
        writeExportFile: (file) async => File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}${file.fileName}',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('导出患者数据'), findsOneWidget);

      await tester.tap(find.text('导出患者数据'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(patientRepository.exportCallCount, 1);
      expect(find.text('导出成功'), findsOneWidget);
      expect(find.text('文件已下载：demo.zip'), findsOneWidget);

      await tester.tap(find.text('稍后'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('导出成功'), findsNothing);
    });

    testWidgets('shows snackbar when export fails', (tester) async {
      final profileRepository = _FakeDoctorProfileRepository(
        profile: _profile(fullName: '张医生', hospital: '协和医院'),
      );
      final patientRepository = _FakeDoctorPatientRepository(
        onExport: () async => const Failure<DoctorPatientExportFile>(
          AppError(type: AppErrorType.network, message: '网络连接异常，请稍后再试'),
        ),
      );

      await _pumpMePage(
        tester,
        repository: profileRepository,
        patientRepository: patientRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('导出患者数据'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(patientRepository.exportCallCount, 1);
      expect(find.text('网络连接异常，请稍后再试'), findsOneWidget);
      expect(find.text('导出成功'), findsNothing);
    });
  });
}

Future<void> _pumpMePage(
  WidgetTester tester, {
  required _FakeDoctorProfileRepository repository,
  DoctorAuthRepository? authRepository,
  DoctorPatientRepository? patientRepository,
  Future<File> Function(DoctorPatientExportFile file)? writeExportFile,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        doctorProfileRepositoryProvider.overrideWithValue(repository),
        if (authRepository != null)
          doctorAuthRepositoryProvider.overrideWithValue(authRepository),
        if (patientRepository != null)
          doctorPatientRepositoryProvider.overrideWithValue(patientRepository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: DoctorMePage(writeExportFile: writeExportFile),
      ),
    ),
  );
}

DoctorProfile _profile({
  required String fullName,
  required String hospital,
  String phone = '13800138000',
}) {
  return DoctorProfile(
    doctorId: 12,
    phone: phone,
    fullName: fullName,
    hospital: hospital,
  );
}

final class _FakeDoctorProfileRepository implements DoctorProfileRepository {
  _FakeDoctorProfileRepository({required DoctorProfile profile})
    : _profile = profile;

  DoctorProfile _profile;
  DoctorThresholds _thresholds = const DoctorThresholds(
    phq9Threshold: 10,
    gad7Threshold: 7,
  );

  int updateProfileCallCount = 0;

  @override
  Future<Result<DoctorProfile>> fetchProfile() async {
    return Success<DoctorProfile>(_profile);
  }

  @override
  Future<Result<DoctorThresholds>> fetchThresholds() async {
    return Success<DoctorThresholds>(_thresholds);
  }

  @override
  Future<Result<DoctorProfile>> updateProfile(
    DoctorProfileUpdatePayload payload,
  ) async {
    updateProfileCallCount += 1;
    _profile = DoctorProfile(
      doctorId: _profile.doctorId,
      phone: _profile.phone,
      fullName: payload.fullName.trim(),
      hospital: payload.hospital.trim(),
      title: _profile.title,
    );
    return Success<DoctorProfile>(_profile);
  }

  @override
  Future<Result<DoctorThresholds>> updateThresholds(
    DoctorThresholds payload,
  ) async {
    _thresholds = payload;
    return Success<DoctorThresholds>(_thresholds);
  }
}

final class _FakeDoctorPatientRepository implements DoctorPatientRepository {
  _FakeDoctorPatientRepository({required this.onExport});

  final Future<Result<DoctorPatientExportFile>> Function() onExport;

  int exportCallCount = 0;

  @override
  Future<Result<DoctorPatientExportFile>> exportPatients() {
    exportCallCount += 1;
    return onExport();
  }

  @override
  Future<Result<DoctorPatientListResult>> fetchPatients({
    required DoctorPatientQuery query,
    int limit = 20,
    String? cursor,
  }) async {
    return const Success<DoctorPatientListResult>(
      DoctorPatientListResult(items: <DoctorPatient>[], nextCursor: null),
    );
  }

  @override
  Future<Result<DoctorPatientGrouping>> updateGrouping({
    required int patientUserId,
    required DoctorPatientGrouping payload,
  }) async {
    return const Success<DoctorPatientGrouping>(
      DoctorPatientGrouping(severityGroup: null),
    );
  }

  @override
  Future<Result<List<DoctorPatientGroupingHistoryItem>>> fetchGroupingHistory({
    required int patientUserId,
    int limit = 20,
    String? cursor,
  }) async {
    return const Success<List<DoctorPatientGroupingHistoryItem>>(
      <DoctorPatientGroupingHistoryItem>[],
    );
  }

  @override
  Future<Result<List<DoctorPatientGroupOption>>> fetchPatientGroups() async {
    return const Success<List<DoctorPatientGroupOption>>(
      <DoctorPatientGroupOption>[],
    );
  }

  @override
  Future<Result<DoctorPatientGroupOption>> createPatientGroup({
    required String severityGroup,
  }) async {
    return Success<DoctorPatientGroupOption>(
      DoctorPatientGroupOption(severityGroup: severityGroup, patientCount: 0),
    );
  }

  @override
  Future<Result<DoctorPatientDiagnosisUpdateResult>> updateDiagnosis({
    required int patientUserId,
    required DoctorPatientDiagnosisUpdatePayload payload,
  }) async {
    return Success<DoctorPatientDiagnosisUpdateResult>(
      DoctorPatientDiagnosisUpdateResult(
        patientUserId: patientUserId,
        diagnosis: payload.diagnosis,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<DoctorPatientProfile>> fetchPatientProfile({
    required int patientUserId,
  }) async {
    return const Success<DoctorPatientProfile>(
      DoctorPatientProfile(
        patientUserId: null,
        phone: null,
        fullName: null,
        gender: null,
        birthDate: null,
        heightCm: null,
        weightKg: null,
        waistCm: null,
        usesTcm: null,
        diseaseHistory: <String>[],
      ),
    );
  }
}

final class _FakeDoctorAuthRepository implements DoctorAuthRepository {
  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<DoctorLoginCheckResult>> loginCheck({
    required String phone,
  }) async {
    return const Failure<DoctorLoginCheckResult>(
      AppError(type: AppErrorType.unknown, message: 'unused in test'),
    );
  }

  @override
  Future<Result<DoctorAuthSessionResult>> loginDirect({
    required String phone,
    required String ticket,
  }) async {
    return const Failure<DoctorAuthSessionResult>(
      AppError(type: AppErrorType.unknown, message: 'unused in test'),
    );
  }

  @override
  Future<Result<DoctorAuthSessionResult>> loginPassword({
    required String phone,
    required String password,
  }) async {
    return const Failure<DoctorAuthSessionResult>(
      AppError(type: AppErrorType.unknown, message: 'unused in test'),
    );
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<DoctorAuthSessionResult>> refreshToken() async {
    return const Failure<DoctorAuthSessionResult>(
      AppError(type: AppErrorType.unknown, message: 'unused in test'),
    );
  }

  @override
  Future<Result<DoctorAuthSessionResult>> register({
    required String phone,
    required String smsCode,
    required String password,
  }) async {
    return const Failure<DoctorAuthSessionResult>(
      AppError(type: AppErrorType.unknown, message: 'unused in test'),
    );
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String smsCode,
    required String newPassword,
  }) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> sendSmsCode({
    required String phone,
    required DoctorSmsPurpose purpose,
  }) async {
    return const Success<void>(null);
  }
}
