import 'package:app_ui/app_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeScaleRadarMetric', () {
    test('SCL90 averageScore keeps 1~5 axis', () {
      final normalized = normalizeScaleRadarMetric(
        const ScaleRadarMetricInput(
          scaleCode: 'SCL90',
          dimensionKey: 'somatization',
          dimensionName: '躯体化',
          averageScore: 1.17,
        ),
      );

      expect(normalized, isNotNull);
      expect(normalized!.displayValue, closeTo(1.17, 0.0001));
      expect(normalized.axisMax, 5);
      expect(normalized.plotValue / normalized.axisMax, closeTo(0.234, 0.001));
    });

    test('SCL90 rawScore converts to average by factor item count', () {
      final normalized = normalizeScaleRadarMetric(
        const ScaleRadarMetricInput(
          scaleCode: 'SCL90',
          dimensionKey: 'somatization',
          dimensionName: '躯体化',
          rawScore: 14,
        ),
      );

      expect(normalized, isNotNull);
      expect(normalized!.displayValue, closeTo(14 / 12, 0.0001));
      expect(normalized.axisMax, 5);
    });

    test('SCL90 chinese dimension name can map factor count', () {
      final normalized = normalizeScaleRadarMetric(
        const ScaleRadarMetricInput(
          scaleCode: 'SCL90',
          dimensionKey: '',
          dimensionName: '躯体化',
          rawScore: 14,
        ),
      );

      expect(normalized, isNotNull);
      expect(normalized!.displayValue, closeTo(14 / 12, 0.0001));
    });

    test('PSQI uses fixed axis 3', () {
      final normalized = normalizeScaleRadarMetric(
        const ScaleRadarMetricInput(
          scaleCode: 'PSQI',
          dimensionKey: 'C1',
          dimensionName: '睡眠质量',
          rawScore: 2,
        ),
      );

      expect(normalized, isNotNull);
      expect(normalized!.displayValue, 2);
      expect(normalized.axisMax, 3);
    });

    test('EPQ standard score uses axis 100', () {
      final normalized = normalizeScaleRadarMetric(
        const ScaleRadarMetricInput(
          scaleCode: 'EPQ',
          dimensionKey: 'E',
          dimensionName: '外向',
          standardScore: 62,
        ),
      );

      expect(normalized, isNotNull);
      expect(normalized!.displayValue, 62);
      expect(normalized.axisMax, 100);
    });

    test('EPQ raw E uses axis 21', () {
      final normalized = normalizeScaleRadarMetric(
        const ScaleRadarMetricInput(
          scaleCode: 'EPQ',
          dimensionKey: 'E',
          dimensionName: '外向',
          rawScore: 15,
        ),
      );

      expect(normalized, isNotNull);
      expect(normalized!.displayValue, 15);
      expect(normalized.axisMax, 21);
    });

    test('unknown scale uses stable fallback bound', () {
      final normalized = normalizeScaleRadarMetric(
        const ScaleRadarMetricInput(
          scaleCode: 'CUSTOM',
          dimensionKey: 'd1',
          dimensionName: '维度1',
          rawScore: 8.4,
        ),
      );

      expect(normalized, isNotNull);
      expect(normalized!.axisMax, 10);
    });
  });
}
