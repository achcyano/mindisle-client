import 'package:app_core/app_core.dart';
import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';
import 'package:doctor/features/doctor_binding/domain/repositories/doctor_binding_repository.dart';
import 'package:doctor/features/doctor_binding/presentation/binding/doctor_binding_controller.dart';
import 'package:doctor/features/doctor_binding/presentation/providers/doctor_binding_providers.dart';
import 'package:doctor/view/pages/bindings/bindings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('DoctorBindingController', () {
    test('marks empty binding code as an error', () async {
      final repository = _FakeDoctorBindingRepository(
        codeResults: <Result<DoctorBindingCode>>[
          const Success<DoctorBindingCode>(
            DoctorBindingCode(code: '', expiresAt: null, qrPayload: ''),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          doctorBindingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(doctorBindingControllerProvider.notifier)
          .refreshBindingCode();

      final state = container.read(doctorBindingControllerProvider);
      expect(state.data.latestCode, isNull);
      expect(state.errorMessage, '绑定码数据不完整，请稍后重试');
    });
  });

  group('DoctorBindingsPage', () {
    testWidgets('fetches a binding code when switching back to the tab', (
      tester,
    ) async {
      final repository = _FakeDoctorBindingRepository(
        codeResults: <Result<DoctorBindingCode>>[
          _successCode('ABCD1234'),
          _successCode('ZXCV9876'),
        ],
      );
      final tabIndexListenable = ValueNotifier<int>(0);
      addTearDown(tabIndexListenable.dispose);

      await _pumpBindingsPage(
        tester,
        repository: repository,
        tabIndexListenable: tabIndexListenable,
      );

      expect(repository.createBindingCodeCallCount, 0);

      tabIndexListenable.value = DoctorBindingsPage.tabIndex;
      await tester.pumpAndSettle();

      expect(repository.createBindingCodeCallCount, 1);
      expect(find.text('ABCD1234'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      tabIndexListenable.value = 0;
      await tester.pumpAndSettle();
      tabIndexListenable.value = DoctorBindingsPage.tabIndex;
      await tester.pumpAndSettle();

      expect(repository.createBindingCodeCallCount, 2);
      expect(find.text('ZXCV9876'), findsOneWidget);
    });

    testWidgets('supports pull to refresh after a successful load', (
      tester,
    ) async {
      final repository = _FakeDoctorBindingRepository(
        codeResults: <Result<DoctorBindingCode>>[
          _successCode('ABCD1234'),
          _successCode('ZXCV9876'),
        ],
      );
      final tabIndexListenable = ValueNotifier<int>(
        DoctorBindingsPage.tabIndex,
      );
      addTearDown(tabIndexListenable.dispose);

      await _pumpBindingsPage(
        tester,
        repository: repository,
        tabIndexListenable: tabIndexListenable,
      );
      await tester.pumpAndSettle();

      expect(repository.createBindingCodeCallCount, 1);
      expect(find.text('ABCD1234'), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(repository.createBindingCodeCallCount, 2);
      expect(find.text('ZXCV9876'), findsOneWidget);
    });

    testWidgets('shows retry error card and retries when tapped', (
      tester,
    ) async {
      final repository = _FakeDoctorBindingRepository(
        codeResults: <Result<DoctorBindingCode>>[
          const Failure<DoctorBindingCode>(
            AppError(type: AppErrorType.network, message: '网络开小差了'),
          ),
          _successCode('ABCD1234'),
        ],
      );
      final tabIndexListenable = ValueNotifier<int>(
        DoctorBindingsPage.tabIndex,
      );
      addTearDown(tabIndexListenable.dispose);

      await _pumpBindingsPage(
        tester,
        repository: repository,
        tabIndexListenable: tabIndexListenable,
      );
      await tester.pumpAndSettle();

      expect(find.byType(RetryErrorCard), findsOneWidget);
      expect(find.text('获取绑定码失败'), findsOneWidget);
      expect(find.text('网络开小差了'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      final cardTop = tester.getTopLeft(find.byType(RetryErrorCard)).dy;
      expect(cardTop, lessThan(200));

      await tester.tap(find.byType(RetryErrorCard));
      await tester.pump();
      expect(repository.createBindingCodeCallCount, 2);
      await tester.pumpAndSettle();

      expect(find.byType(RetryErrorCard), findsNothing);
      expect(find.text('ABCD1234'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });
}

Future<void> _pumpBindingsPage(
  WidgetTester tester, {
  required _FakeDoctorBindingRepository repository,
  required ValueNotifier<int> tabIndexListenable,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        doctorBindingRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: DoctorBindingsPage(currentTabIndexListenable: tabIndexListenable),
      ),
    ),
  );
}

Result<DoctorBindingCode> _successCode(String code) {
  return Success<DoctorBindingCode>(
    DoctorBindingCode(code: code, expiresAt: null, qrPayload: ''),
  );
}

final class _FakeDoctorBindingRepository implements DoctorBindingRepository {
  _FakeDoctorBindingRepository({List<Result<DoctorBindingCode>>? codeResults})
    : _codeResults = codeResults ?? <Result<DoctorBindingCode>>[];

  final List<Result<DoctorBindingCode>> _codeResults;

  int createBindingCodeCallCount = 0;

  @override
  Future<Result<DoctorBindingCode>> createBindingCode() async {
    createBindingCodeCallCount += 1;
    return _codeResults.removeAt(0);
  }

  @override
  Future<Result<DoctorBindingHistoryResult>> fetchBindingHistory({
    int limit = 20,
    String? cursor,
    int? patientUserId,
  }) async {
    return const Success<DoctorBindingHistoryResult>(
      DoctorBindingHistoryResult(
        items: <DoctorBindingHistoryItem>[],
        nextCursor: null,
      ),
    );
  }
}
