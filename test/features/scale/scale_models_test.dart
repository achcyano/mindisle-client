import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindisle_client/features/scale/data/models/scale_models.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';

void main() {
  group('Scale sample json parsing', () {
    test('parses scale detail sample', () {
      final root = Directory.current.path;
      final jsonFile = File('$root/docs/real-sample-scale-detail.json');
      final raw =
          jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(raw['data'] as Map);

      final detail = ScaleDetailDto.fromJson(data).toDomain();

      expect(detail.scaleId, 1);
      expect(detail.code, 'PHQ9');
      expect(detail.questions.length, 10);
      expect(detail.questions.first.type, ScaleQuestionType.singleChoice);
      expect(detail.questions.first.options.length, 4);
    });

    test('parses session detail sample', () {
      final root = Directory.current.path;
      final jsonFile = File('$root/docs/real-sample-session-detail.json');
      final raw =
          jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(raw['data'] as Map);

      final sessionDetail = ScaleSessionDetailDto.fromJson(data).toDomain();

      expect(sessionDetail.session.sessionId, 1);
      expect(sessionDetail.session.status, ScaleSessionStatus.inProgress);
      expect(sessionDetail.answers, isEmpty);
      expect(sessionDetail.unansweredRequiredQuestionIds.length, 9);
    });

    test('parses result sample', () {
      final root = Directory.current.path;
      final jsonFile = File('$root/docs/real-sample-session-result.json');
      final raw =
          jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(raw['data'] as Map);

      final result = ScaleResultDto.fromJson(data).toDomain();

      expect(result.sessionId, 1);
      expect(result.totalScore, 9);
      expect(result.bandLevelCode, 'mild');
      expect(result.resultFlags, contains('SUICIDE_RISK'));
      expect(result.dimensionResults.length, 1);
    });
  });
}
