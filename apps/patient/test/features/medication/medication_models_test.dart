import 'package:flutter_test/flutter_test.dart';
import 'package:patient/features/medication/data/models/medication_models.dart';
import 'package:patient/features/medication/domain/entities/medication_entities.dart';

void main() {
  group('UpsertMedicationRequestDto', () {
    test('TABLET unit keeps strength fields', () {
      const payload = UpsertMedicationPayload(
        drugName: '阿司匹林',
        doseTimes: ['08:00', '12:00'],
        endDate: '2026-03-31',
        doseAmount: 1,
        doseUnit: MedicationDoseUnit.tablet,
        tabletStrengthAmount: 500,
        tabletStrengthUnit: MedicationStrengthUnit.mg,
      );

      final json = UpsertMedicationRequestDto.fromDomain(payload).toJson();

      expect(json['doseUnit'], 'TABLET');
      expect(json['tabletStrengthAmount'], 500);
      expect(json['tabletStrengthUnit'], 'MG');
    });

    test('MG/G unit clears strength fields', () {
      const payload = UpsertMedicationPayload(
        drugName: '维生素C',
        doseTimes: ['09:00'],
        endDate: '2026-04-01',
        doseAmount: 250,
        doseUnit: MedicationDoseUnit.mg,
        tabletStrengthAmount: 500,
        tabletStrengthUnit: MedicationStrengthUnit.mg,
      );

      final json = UpsertMedicationRequestDto.fromDomain(payload).toJson();

      expect(json['doseUnit'], 'MG');
      expect(json['tabletStrengthAmount'], isNull);
      expect(json['tabletStrengthUnit'], isNull);
    });
  });

  group('MedicationListResultDto', () {
    test('parses list payload', () {
      final dto = MedicationListResultDto.fromJson({
        'items': [
          {
            'medicationId': 12,
            'drugName': '阿司匹林',
            'doseTimes': ['08:00', '12:30', '19:00'],
            'recordedDate': '2026-03-02',
            'endDate': '2026-03-31',
            'doseAmount': 1.0,
            'doseUnit': 'TABLET',
            'tabletStrengthAmount': 500.0,
            'tabletStrengthUnit': 'MG',
            'isActive': true,
            'createdAt': '2026-03-02T07:00:00Z',
            'updatedAt': '2026-03-02T07:00:00Z',
          },
        ],
        'activeCount': 1,
        'nextCursor': null,
      });

      final result = dto.toDomain();
      expect(result.items, hasLength(1));
      expect(result.activeCount, 1);
      expect(result.nextCursor, isNull);

      final record = result.items.first;
      expect(record.medicationId, 12);
      expect(record.drugName, '阿司匹林');
      expect(record.doseUnit, MedicationDoseUnit.tablet);
      expect(record.tabletStrengthUnit, MedicationStrengthUnit.mg);
      expect(record.doseTimes, ['08:00', '12:30', '19:00']);
    });
  });
}
