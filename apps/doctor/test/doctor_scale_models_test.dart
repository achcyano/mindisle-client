import 'package:doctor/features/doctor_scale/data/models/doctor_scale_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Doctor scale models', () {
    test('decodeDoctorScaleSessionResult parses complete payload', () {
      final result = decodeDoctorScaleSessionResult(<String, dynamic>{
        'sessionId': 18,
        'totalScore': 14.5,
        'dimensionScores': <String, dynamic>{'睡眠': 2.0, '情绪': 4.0},
        'dimensionResults': <Map<String, dynamic>>[
          <String, dynamic>{
            'dimensionKey': 'sleep',
            'dimensionName': '睡眠',
            'rawScore': 2.0,
            'averageScore': 1.5,
            'standardScore': 60.0,
            'levelCode': 'MILD',
            'levelName': '轻度',
            'interpretation': '存在轻度问题',
            'extraMetrics': <String, dynamic>{'p': 90},
          },
        ],
        'resultFlags': <String>['SUICIDE_RISK', ''],
        'bandLevelCode': 'mild',
        'bandLevelName': '轻度',
        'resultText': '请关注睡眠情况',
        'computedAt': '2026-03-28T08:00:00Z',
      });

      expect(result.sessionId, 18);
      expect(result.totalScore, 14.5);
      expect(result.dimensionScores['睡眠'], 2.0);
      expect(result.dimensionResults, hasLength(1));
      expect(result.dimensionResults.first.levelName, '轻度');
      expect(result.dimensionResults.first.extraMetrics['p'], 90);
      expect(result.resultFlags, <String>['SUICIDE_RISK']);
      expect(result.bandLevelCode, 'mild');
      expect(result.bandLevelName, '轻度');
      expect(result.resultText, '请关注睡眠情况');
      expect(result.computedAt, DateTime.parse('2026-03-28T08:00:00Z'));
    });

    test('decodeDoctorScaleSessionResult falls back to defaults', () {
      final result = decodeDoctorScaleSessionResult(<String, dynamic>{
        'sessionId': '9',
      });

      expect(result.sessionId, 9);
      expect(result.totalScore, isNull);
      expect(result.dimensionScores, isEmpty);
      expect(result.dimensionResults, isEmpty);
      expect(result.resultFlags, isEmpty);
      expect(result.computedAt, isNull);
    });
  });
}
