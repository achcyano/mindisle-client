import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/features/event/domain/repositories/event_repository.dart';
import 'package:patient/features/event/presentation/binding/patient_doctor_binding_controller.dart';
import 'package:patient/features/event/presentation/providers/event_providers.dart';
import 'package:patient/view/pages/doctor_binding/doctor_binding_page.dart';
import 'package:patient/view/pages/home/home_event_card.dart';

void main() {
  group('HomeEventCard', () {
    test('bind doctor event is actionable', () {
      final item = UserEventItem(
        eventName: 'DOCTOR_BIND_REQUIRED',
        eventType: UserEventType.bindDoctor,
        dueAt: null,
        persistent: true,
        rawPayload: const <String, dynamic>{},
      );

      expect(HomeEventCard.isActionable(item), isTrue);
    });
  });

  group('PatientDoctorBindingPage', () {
    testWidgets('binds doctor with manual 5-digit code', (tester) async {
      final repository = _FakeEventRepository(
        statusResult: Success<DoctorBindingStatus>(_status(isBound: false)),
        bindResult: Success<DoctorBindingStatus>(_status(isBound: true)),
      );
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const PatientDoctorBindingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = container.read(
        patientDoctorBindingControllerProvider.notifier,
      );
      controller.inputDigit('1');
      controller.inputDigit('2');
      controller.inputDigit('3');
      controller.inputDigit('4');
      controller.inputDigit('5');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.bindCodes, <String>['12345']);
      expect(find.text('张医生'), findsOneWidget);
    });

    testWidgets('shows contact-doctor hint when bound', (tester) async {
      final repository = _FakeEventRepository(
        statusResult: Success<DoctorBindingStatus>(
          _status(isBound: true, hospital: '杭州市中医院'),
        ),
      );
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const PatientDoctorBindingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('张医生'), findsOneWidget);
      expect(find.text('杭州市中医院'), findsOneWidget);
      expect(find.text('请联系医生解除绑定'), findsOneWidget);
      expect(find.text('解除绑定'), findsNothing);
    });
  });
}

DoctorBindingStatus _status({required bool isBound, String? hospital}) {
  return DoctorBindingStatus(
    isBound: isBound,
    boundAt: DateTime.parse('2026-03-21T08:00:00Z'),
    unboundAt: null,
    updatedAt: DateTime.parse('2026-03-21T08:00:00Z'),
    currentDoctorId: isBound ? 99 : null,
    currentDoctorName: isBound ? '张医生' : null,
    currentDoctorHospital: isBound ? hospital : null,
  );
}

final class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({
    Result<DoctorBindingStatus>? statusResult,
    Result<DoctorBindingStatus>? bindResult,
    Result<DoctorBindingStatus>? unbindResult,
  }) : _statusResult =
           statusResult ??
           Success<DoctorBindingStatus>(_status(isBound: false)),
       _bindResult =
           bindResult ?? Success<DoctorBindingStatus>(_status(isBound: true)),
       _unbindResult =
           unbindResult ??
           Success<DoctorBindingStatus>(_status(isBound: false));

  final Result<DoctorBindingStatus> _statusResult;
  final Result<DoctorBindingStatus> _bindResult;
  final Result<DoctorBindingStatus> _unbindResult;

  final List<String> bindCodes = <String>[];
  int unbindCalls = 0;

  @override
  Future<Result<DoctorBindingStatus>> bindDoctor({
    required String bindingCode,
  }) async {
    bindCodes.add(bindingCode);
    return _bindResult;
  }

  @override
  Future<Result<UserEventList>> fetchUserEvents() async {
    return const Success<UserEventList>(
      UserEventList(generatedAt: null, items: <UserEventItem>[]),
    );
  }

  @override
  Future<Result<DoctorBindingHistoryResult>> fetchDoctorBindingHistory({
    int limit = 20,
    String? cursor,
  }) async {
    return const Success<DoctorBindingHistoryResult>(
      DoctorBindingHistoryResult(
        items: <DoctorBindingHistoryItem>[],
        nextCursor: null,
      ),
    );
  }

  @override
  Future<Result<DoctorBindingStatus>> getDoctorBindingStatus() async {
    return _statusResult;
  }

  @override
  Future<Result<DoctorBindingStatus>> unbindDoctor() async {
    unbindCalls += 1;
    return _unbindResult;
  }
}
