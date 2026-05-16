import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient/features/scale/data/models/scale_models.dart';
import 'package:patient/features/scale/domain/entities/scale_entities.dart';

void main() {
  group('Scale sample json parsing', () {
    test('parses scale detail sample', () {
      final root = _workspaceRoot;
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
      final root = _workspaceRoot;
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
      final root = _workspaceRoot;
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

    test('parses scale summary lastCompletedAt', () {
      final dto = ScaleSummaryDto.fromJson(const <String, dynamic>{
        'scaleId': 1,
        'code': 'PHQ9',
        'name': 'PHQ-9',
        'description': '抑郁筛查',
        'status': 'PUBLISHED',
        'lastCompletedAt': '2026-02-24T21:30:00+08:00',
      });

      final summary = dto.toDomain();
      expect(summary.lastCompletedAt, isNotNull);
      expect(summary.lastCompletedAt!.toUtc().hour, 13);
      expect(summary.lastCompletedAt!.toUtc().minute, 30);
    });

    test('parses webview delivery fields on summary and detail', () {
      final summary = ScaleSummaryDto.fromJson(const <String, dynamic>{
        'scaleId': 8,
        'code': 'TESS',
        'name': 'TESS 药物副反应自评',
        'description': '副反应自评',
        'status': 'PUBLISHED',
        'deliveryMode': 'WEBVIEW',
        'webPath': '/web/scales/TESS',
      }).toDomain();

      final detail = ScaleDetailDto.fromJson(const <String, dynamic>{
        'scaleId': 8,
        'code': 'TESS',
        'name': 'TESS 药物副反应自评',
        'description': '副反应自评',
        'status': 'PUBLISHED',
        'deliveryMode': 'WEBVIEW',
        'webPath': '/web/scales/TESS',
        'questions': <Map<String, dynamic>>[],
      }).toDomain();

      expect(summary.deliveryMode, ScaleDeliveryMode.webview);
      expect(summary.webPath, '/web/scales/TESS');
      expect(detail.deliveryMode, ScaleDeliveryMode.webview);
      expect(detail.webPath, '/web/scales/TESS');
    });

    test('parses history page dto with nextCursor', () {
      final dto = ScaleHistoryPageDto.fromJson(const <String, dynamic>{
        'items': <Map<String, dynamic>>[
          {
            'sessionId': 11,
            'scaleId': 7,
            'scaleCode': 'PHQ9',
            'scaleName': 'PHQ-9',
            'totalScore': 9,
            'submittedAt': '2026-03-20T10:00:00Z',
          },
        ],
        'nextCursor': 'abc123',
      });

      final page = dto.toDomain();
      expect(page.items, hasLength(1));
      expect(page.items.first.sessionId, 11);
      expect(page.nextCursor, 'abc123');
    });

    test('parses history webview delivery fields', () {
      final dto = ScaleHistoryPageDto.fromJson(const <String, dynamic>{
        'items': <Map<String, dynamic>>[
          {
            'sessionId': 99,
            'scaleId': 8,
            'scaleCode': 'TESS',
            'scaleName': 'TESS 药物副反应自评',
            'deliveryMode': 'WEBVIEW',
            'webPath': '/web/scales/TESS?sessionId=99',
          },
        ],
      });

      final item = dto.toDomain().items.single;
      expect(item.deliveryMode, ScaleDeliveryMode.webview);
      expect(item.webPath, '/web/scales/TESS?sessionId=99');
    });
  });
}

String get _workspaceRoot {
  final current = Directory.current;
  if (File('${current.path}/docs/real-sample-scale-detail.json').existsSync()) {
    return current.path;
  }
  return current.parent.parent.path;
}
