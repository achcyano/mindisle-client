import 'package:flutter_test/flutter_test.dart';
import 'package:patient/features/event/data/models/event_models.dart';

void main() {
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
