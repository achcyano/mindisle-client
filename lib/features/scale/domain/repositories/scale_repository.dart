import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';

abstract interface class ScaleRepository {
  Future<Result<List<ScaleSummary>>> fetchScales({
    int limit,
    String? cursor,
    String? status,
  });

  Future<Result<ScaleDetail>> fetchScaleDetail({required String scaleRef});

  Future<Result<ScaleCreateSessionResult>> createOrResumeSession({
    required int scaleId,
  });

  Future<Result<ScaleSessionDetail>> fetchSessionDetail({
    required int sessionId,
  });

  Future<Result<bool>> saveSingleChoiceAnswer({
    required int sessionId,
    required int questionId,
    required int optionId,
  });

  Future<Result<bool>> submitSession({required int sessionId});

  Future<Result<ScaleResult>> fetchSessionResult({required int sessionId});

  Future<Result<List<ScaleHistoryItem>>> fetchHistory({
    int limit,
    String? cursor,
  });

  Future<Result<bool>> deleteSession({required int sessionId});

  Stream<ScaleAssistEvent> assistQuestion({
    required int sessionId,
    required int questionId,
    required String userDraftAnswer,
  });
}
