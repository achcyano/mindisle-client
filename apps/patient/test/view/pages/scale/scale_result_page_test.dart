import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/features/scale/domain/entities/scale_entities.dart';
import 'package:patient/features/scale/domain/repositories/scale_repository.dart';
import 'package:patient/features/scale/presentation/providers/scale_providers.dart';
import 'package:patient/features/scale/presentation/result/scale_result_args.dart';
import 'package:patient/view/pages/scale/scale_result_page.dart';

void main() {
  testWidgets('shows result body before detail and history finish', (
    tester,
  ) async {
    final detailCompleter = Completer<Result<ScaleDetail>>();
    final historyCompleter = Completer<Result<ScaleHistoryPage>>();
    final repository = _FakeScaleRepository(
      fetchSessionResultHandler: ({required sessionId}) async {
        return Success(
          ScaleResult(
            sessionId: sessionId,
            totalScore: 12,
            bandLevelName: '轻度',
            resultText: '主结论',
          ),
        );
      },
      fetchScaleDetailHandler: ({required scaleRef}) => detailCompleter.future,
      fetchHistoryHandler: ({required limit, required cursor}) =>
          historyCompleter.future,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [scaleRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: ScaleResultPage(
            args: const ScaleResultArgs(
              sessionId: 99,
              scaleId: 7,
              scaleName: 'PHQ-9',
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('主结论'), findsOneWidget);
    expect(find.byType(ScaleResultSummaryCard), findsOneWidget);
  });

  testWidgets('loads trend history with internal pagination', (tester) async {
    final historyRequests = <String?>[];
    final repository = _FakeScaleRepository(
      fetchSessionResultHandler: ({required sessionId}) async {
        return Success(
          ScaleResult(
            sessionId: sessionId,
            totalScore: 5,
            bandLevelName: '轻度',
            resultText: '结果',
          ),
        );
      },
      fetchScaleDetailHandler: ({required scaleRef}) async {
        return Success(
          ScaleDetail(
            scaleId: 7,
            code: 'PHQ9',
            name: 'PHQ-9',
            description: '',
            status: ScalePublishStatus.published,
          ),
        );
      },
      fetchHistoryHandler: ({required limit, required cursor}) async {
        historyRequests.add(cursor);
        if (cursor == null) {
          return Success(
            ScaleHistoryPage(
              items: <ScaleHistoryItem>[
                ScaleHistoryItem(
                  sessionId: 10,
                  scaleId: 7,
                  scaleCode: 'PHQ9',
                  scaleName: 'PHQ-9',
                  totalScore: 3,
                  submittedAt: DateTime.parse('2026-03-01T00:00:00Z'),
                ),
                ScaleHistoryItem(
                  sessionId: 11,
                  scaleId: 8,
                  scaleCode: 'GAD7',
                  scaleName: 'GAD-7',
                  totalScore: 2,
                  submittedAt: DateTime.parse('2026-03-02T00:00:00Z'),
                ),
              ],
              nextCursor: 'c2',
            ),
          );
        }
        return Success(
          ScaleHistoryPage(
            items: <ScaleHistoryItem>[
              ScaleHistoryItem(
                sessionId: 12,
                scaleId: 7,
                scaleCode: 'PHQ9',
                scaleName: 'PHQ-9',
                totalScore: 4,
                submittedAt: DateTime.parse('2026-03-03T00:00:00Z'),
              ),
            ],
            nextCursor: null,
          ),
        );
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [scaleRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: ScaleResultPage(
            args: const ScaleResultArgs(
              sessionId: 99,
              scaleId: 7,
              scaleName: 'PHQ-9',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(historyRequests, <String?>[null, 'c2']);
    expect(find.byType(ScaleScoreTrendChartCard), findsOneWidget);
  });
}

final class _FakeScaleRepository implements ScaleRepository {
  _FakeScaleRepository({
    required this.fetchSessionResultHandler,
    required this.fetchScaleDetailHandler,
    required this.fetchHistoryHandler,
  });

  final Future<Result<ScaleResult>> Function({required int sessionId})
  fetchSessionResultHandler;
  final Future<Result<ScaleDetail>> Function({required String scaleRef})
  fetchScaleDetailHandler;
  final Future<Result<ScaleHistoryPage>> Function({
    required int limit,
    required String? cursor,
  })
  fetchHistoryHandler;

  @override
  Future<Result<ScaleResult>> fetchSessionResult({required int sessionId}) {
    return fetchSessionResultHandler(sessionId: sessionId);
  }

  @override
  Future<Result<ScaleDetail>> fetchScaleDetail({required String scaleRef}) {
    return fetchScaleDetailHandler(scaleRef: scaleRef);
  }

  @override
  Future<Result<ScaleHistoryPage>> fetchHistory({
    int limit = 20,
    String? cursor,
  }) {
    return fetchHistoryHandler(limit: limit, cursor: cursor);
  }

  @override
  Stream<ScaleAssistEvent> assistQuestion({
    required int sessionId,
    required int questionId,
    required String userDraftAnswer,
  }) {
    return const Stream<ScaleAssistEvent>.empty();
  }

  @override
  Future<Result<ScaleCreateSessionResult>> createOrResumeSession({
    required int scaleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> deleteSession({required int sessionId}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<ScaleSummary>>> fetchScales({
    int limit = 20,
    String? cursor,
    String? status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ScaleSessionDetail>> fetchSessionDetail({
    required int sessionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> saveAnswer({
    required int sessionId,
    required int questionId,
    required Object answer,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> submitSession({required int sessionId}) {
    throw UnimplementedError();
  }
}
