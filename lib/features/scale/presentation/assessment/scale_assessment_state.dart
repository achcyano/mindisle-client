import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';

final class ScaleAssessmentState {
  const ScaleAssessmentState({
    this.initialized = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.detail,
    this.session,
    this.answerDrafts = const <int, ScaleAnswerDraft>{},
    this.unansweredRequiredQuestionIds = const <int>[],
    this.currentQuestionIndex = 0,
    this.savingQuestionIds = const <int>{},
    this.errorMessage,
    this.submittedSessionId,
  });

  final bool initialized;
  final bool isLoading;
  final bool isSubmitting;
  final ScaleDetail? detail;
  final ScaleSession? session;
  final Map<int, ScaleAnswerDraft> answerDrafts;
  final List<int> unansweredRequiredQuestionIds;
  final int currentQuestionIndex;
  final Set<int> savingQuestionIds;
  final String? errorMessage;
  final int? submittedSessionId;

  ScaleAssessmentState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isSubmitting,
    Object? detail = _sentinel,
    Object? session = _sentinel,
    Map<int, ScaleAnswerDraft>? answerDrafts,
    List<int>? unansweredRequiredQuestionIds,
    int? currentQuestionIndex,
    Set<int>? savingQuestionIds,
    Object? errorMessage = _sentinel,
    Object? submittedSessionId = _sentinel,
  }) {
    return ScaleAssessmentState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      detail: identical(detail, _sentinel)
          ? this.detail
          : detail as ScaleDetail?,
      session: identical(session, _sentinel)
          ? this.session
          : session as ScaleSession?,
      answerDrafts: answerDrafts ?? this.answerDrafts,
      unansweredRequiredQuestionIds:
          unansweredRequiredQuestionIds ?? this.unansweredRequiredQuestionIds,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      savingQuestionIds: savingQuestionIds ?? this.savingQuestionIds,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      submittedSessionId: identical(submittedSessionId, _sentinel)
          ? this.submittedSessionId
          : submittedSessionId as int?,
    );
  }
}

const Object _sentinel = Object();
