import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/domain/repositories/scale_repository.dart';

final class FetchScalesUseCase {
  const FetchScalesUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<List<ScaleSummary>>> execute({
    int limit = 20,
    String? cursor,
    String? status,
  }) {
    return _repository.fetchScales(
      limit: limit,
      cursor: cursor,
      status: status,
    );
  }
}

final class FetchScaleDetailUseCase {
  const FetchScaleDetailUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<ScaleDetail>> execute({required String scaleRef}) {
    return _repository.fetchScaleDetail(scaleRef: scaleRef);
  }
}

final class CreateOrResumeScaleSessionUseCase {
  const CreateOrResumeScaleSessionUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<ScaleCreateSessionResult>> execute({required int scaleId}) {
    return _repository.createOrResumeSession(scaleId: scaleId);
  }
}

final class FetchScaleSessionDetailUseCase {
  const FetchScaleSessionDetailUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<ScaleSessionDetail>> execute({required int sessionId}) {
    return _repository.fetchSessionDetail(sessionId: sessionId);
  }
}

final class SaveScaleSingleChoiceAnswerUseCase {
  const SaveScaleSingleChoiceAnswerUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<bool>> execute({
    required int sessionId,
    required int questionId,
    required int optionId,
  }) {
    return _repository.saveSingleChoiceAnswer(
      sessionId: sessionId,
      questionId: questionId,
      optionId: optionId,
    );
  }
}

final class SubmitScaleSessionUseCase {
  const SubmitScaleSessionUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<bool>> execute({required int sessionId}) {
    return _repository.submitSession(sessionId: sessionId);
  }
}

final class FetchScaleSessionResultUseCase {
  const FetchScaleSessionResultUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<ScaleResult>> execute({required int sessionId}) {
    return _repository.fetchSessionResult(sessionId: sessionId);
  }
}

final class FetchScaleHistoryUseCase {
  const FetchScaleHistoryUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<List<ScaleHistoryItem>>> execute({
    int limit = 20,
    String? cursor,
  }) {
    return _repository.fetchHistory(limit: limit, cursor: cursor);
  }
}

final class DeleteScaleSessionUseCase {
  const DeleteScaleSessionUseCase(this._repository);

  final ScaleRepository _repository;

  Future<Result<bool>> execute({required int sessionId}) {
    return _repository.deleteSession(sessionId: sessionId);
  }
}

final class AssistScaleQuestionUseCase {
  const AssistScaleQuestionUseCase(this._repository);

  final ScaleRepository _repository;

  Stream<ScaleAssistEvent> execute({
    required int sessionId,
    required int questionId,
    required String userDraftAnswer,
  }) {
    return _repository.assistQuestion(
      sessionId: sessionId,
      questionId: questionId,
      userDraftAnswer: userDraftAnswer,
    );
  }
}
