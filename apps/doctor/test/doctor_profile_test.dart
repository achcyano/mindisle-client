import 'package:app_core/app_core.dart';
import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/domain/repositories/doctor_auth_repository.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
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
}

Future<void> _pumpMePage(
  WidgetTester tester, {
  required _FakeDoctorProfileRepository repository,
  DoctorAuthRepository? authRepository,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        doctorProfileRepositoryProvider.overrideWithValue(repository),
        if (authRepository != null)
          doctorAuthRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const DoctorMePage()),
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
