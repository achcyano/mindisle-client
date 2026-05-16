import 'package:flutter_test/flutter_test.dart';
import 'package:patient/features/event/data/models/event_models.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';

void main() {
  group('UserEventItemDto', () {
    test('parses webview scale delivery payload', () {
      final dto = UserEventItemDto.fromJson({
        'eventName': 'SCALE_SESSION_IN_PROGRESS',
        'eventType': 'CONTINUE_SCALE_SESSION',
        'dueAt': '2026-05-16T09:00:00+08:00',
        'persistent': true,
        'payload': {
          'scaleId': 8,
          'scaleCode': 'TESS',
          'scaleName': 'TESS 药物副反应自评',
          'sessionId': 99,
          'progress': 50,
          'deliveryMode': 'WEBVIEW',
          'webPath': '/web/scales/TESS?sessionId=99',
        },
      });

      final item = dto.toDomain();
      expect(item.eventType, UserEventType.continueScaleSession);
      expect(item.deliveryMode, EventScaleDeliveryMode.webview);
      expect(item.webPath, '/web/scales/TESS?sessionId=99');
    });
  });

  group('DoctorBindingStatusDto', () {
    test('parses doctor info from current object', () {
      final dto = DoctorBindingStatusDto.fromJson({
        'isBound': true,
        'current': {
          'bindingId': 6,
          'doctorId': 1,
          'doctorName': 'achcyano',
          'doctorHospital': 'hztcm',
          'boundAt': '2026-03-28T03:38:48.018637Z',
        },
        'updatedAt': '2026-03-28T03:40:49.004613Z',
      });

      final status = dto.toDomain();
      expect(status.isBound, isTrue);
      expect(status.currentDoctorId, 1);
      expect(status.currentDoctorName, 'achcyano');
      expect(status.currentDoctorHospital, 'hztcm');
      expect(status.boundAt, DateTime.parse('2026-03-28T03:38:48.018637Z'));
    });
  });
}
