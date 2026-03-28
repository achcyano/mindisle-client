import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/core/result/app_error.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/features/event/domain/repositories/event_repository.dart';
import 'package:patient/features/event/presentation/binding/patient_doctor_binding_controller.dart';
import 'package:patient/features/event/presentation/binding/patient_doctor_binding_state.dart';
import 'package:patient/features/event/presentation/providers/event_providers.dart';

void main() {
  group('PatientDoctorBindingController', () {
    test('initialize loads binding status', () async {
      final repository = _FakeEventRepository(
        statusResult: Success<DoctorBindingStatus>(_status(isBound: false)),
      );
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(patientDoctorBindingControllerProvider.notifier)
          .initialize();

      final state = container.read(patientDoctorBindingControllerProvider);
      expect(state.initialized, isTrue);
      expect(state.isBound, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('manual input submits 5-digit binding code successfully', () async {
      final repository = _FakeEventRepository(
        statusResult: Success<DoctorBindingStatus>(_status(isBound: false)),
        bindResult: Success<DoctorBindingStatus>(_status(isBound: true)),
      );
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(patientDoctorBindingControllerProvider.notifier)
          .initialize();
      final controller = container.read(
        patientDoctorBindingControllerProvider.notifier,
      );

      controller.inputDigit('1');
      controller.inputDigit('2');
      controller.inputDigit('3');
      controller.inputDigit('4');
      controller.inputDigit('5');

      final message = await controller.submitInputCode();
      final state = container.read(patientDoctorBindingControllerProvider);

      expect(message, '绑定成功');
      expect(repository.bindCodes, <String>['12345']);
      expect(state.isBound, isTrue);
      expect(state.status?.currentDoctorId, 99);
    });

    test('invalid scan payload is rejected without bind request', () async {
      final repository = _FakeEventRepository(
        statusResult: Success<DoctorBindingStatus>(_status(isBound: false)),
      );
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(patientDoctorBindingControllerProvider.notifier)
          .initialize();
      final message = await container
          .read(patientDoctorBindingControllerProvider.notifier)
          .submitScannedPayload('doctor://bind?code=12345');

      expect(message, '二维码中未识别到有效的 5 位绑定码');
      expect(repository.bindCodes, isEmpty);
    });

    test('unbind changes state back to unbound', () async {
      final repository = _FakeEventRepository(
        statusResult: Success<DoctorBindingStatus>(_status(isBound: true)),
        unbindResult: Success<DoctorBindingStatus>(_status(isBound: false)),
      );
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(patientDoctorBindingControllerProvider.notifier)
          .initialize();
      final message = await container
          .read(patientDoctorBindingControllerProvider.notifier)
          .unbind();
      final state = container.read(patientDoctorBindingControllerProvider);

      expect(message, '已解除医生绑定');
      expect(repository.unbindCalls, 1);
      expect(state.isBound, isFalse);
      expect(state.mode, PatientDoctorBindingMode.manual);
    });

    test(
      'submit input with invalid code length returns validation message',
      () async {
        final repository = _FakeEventRepository(
          statusResult: Success<DoctorBindingStatus>(_status(isBound: false)),
        );
        final container = ProviderContainer(
          overrides: [eventRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container
            .read(patientDoctorBindingControllerProvider.notifier)
            .initialize();
        final controller = container.read(
          patientDoctorBindingControllerProvider.notifier,
        );
        controller.inputDigit('1');
        controller.inputDigit('2');

        final message = await controller.submitInputCode();
        final state = container.read(patientDoctorBindingControllerProvider);

        expect(message, '请输入 5 位数字绑定码');
        expect(state.errorMessage, '请输入 5 位数字绑定码');
        expect(repository.bindCodes, isEmpty);
      },
    );

    test('initialize failure keeps message and does not crash', () async {
      final repository = _FakeEventRepository(
        statusResult: const Failure<DoctorBindingStatus>(
          AppError(type: AppErrorType.network, message: '网络异常'),
        ),
      );
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(patientDoctorBindingControllerProvider.notifier)
          .initialize();
      final state = container.read(patientDoctorBindingControllerProvider);

      expect(state.initialized, isTrue);
      expect(state.status, isNull);
      expect(state.errorMessage, '网络异常');
    });
  });
}

DoctorBindingStatus _status({required bool isBound}) {
  return DoctorBindingStatus(
    isBound: isBound,
    boundAt: DateTime.parse('2026-03-21T08:00:00Z'),
    unboundAt: null,
    updatedAt: DateTime.parse('2026-03-21T08:00:00Z'),
    currentDoctorId: isBound ? 99 : null,
    currentDoctorName: isBound ? '张医生' : null,
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
