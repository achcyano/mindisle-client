import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_assessment_args.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_assessment_state.dart';
import 'package:mindisle_client/features/scale/presentation/providers/scale_providers.dart';

final scaleAssessmentControllerProvider = StateNotifierProvider.autoDispose
    .family<
      ScaleAssessmentController,
      ScaleAssessmentState,
      ScaleAssessmentArgs
    >((ref, args) {
      return ScaleAssessmentController(ref, args);
    });

final class ScaleAssessmentController
    extends StateNotifier<ScaleAssessmentState> {
  ScaleAssessmentController(this._ref, this._args)
    : super(const ScaleAssessmentState());

  final Ref _ref;
  final ScaleAssessmentArgs _args;

  Future<void> initialize() async {
    if (state.initialized) return;
    state = state.copyWith(
      initialized: true,
      isLoading: true,
      errorMessage: null,
    );

    final detailFuture = _ref
        .read(fetchScaleDetailUseCaseProvider)
        .execute(scaleRef: _args.scaleId.toString());
    final sessionFuture = _ref
        .read(fetchScaleSessionDetailUseCaseProvider)
        .execute(sessionId: _args.sessionId);
    final detailResult = await detailFuture;
    final sessionResult = await sessionFuture;

    switch (detailResult) {
      case Failure<ScaleDetail>(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return;
      case Success<ScaleDetail>(data: final detail):
        switch (sessionResult) {
          case Failure<ScaleSessionDetail>(error: final error):
            state = state.copyWith(
              isLoading: false,
              detail: detail,
              errorMessage: error.message,
            );
            return;
          case Success<ScaleSessionDetail>(data: final sessionDetail):
            final answerMap = _buildSingleChoiceAnswerMap(
              sessionDetail.answers,
            );
            final initialIndex = _findInitialQuestionIndex(
              detail.questions,
              answerMap,
            );
            state = state.copyWith(
              isLoading: false,
              detail: detail,
              session: sessionDetail.session,
              singleChoiceAnswers: answerMap,
              unansweredRequiredQuestionIds:
                  sessionDetail.unansweredRequiredQuestionIds,
              currentQuestionIndex: initialIndex,
            );
            return;
        }
    }
  }

  Future<void> selectSingleChoice({
    required int questionId,
    required int optionId,
  }) async {
    if (state.isSubmitting || state.savingQuestionIds.contains(questionId)) {
      return;
    }

    final previousAnswers = Map<int, int>.from(state.singleChoiceAnswers);
    final previousUnanswered = List<int>.from(
      state.unansweredRequiredQuestionIds,
    );
    final nextAnswers = Map<int, int>.from(state.singleChoiceAnswers);
    nextAnswers[questionId] = optionId;
    final nextUnanswered = List<int>.from(previousUnanswered)
      ..removeWhere((it) => it == questionId);
    final savingIds = Set<int>.from(state.savingQuestionIds)..add(questionId);

    state = state.copyWith(
      singleChoiceAnswers: nextAnswers,
      unansweredRequiredQuestionIds: nextUnanswered,
      savingQuestionIds: savingIds,
      errorMessage: null,
    );

    final result = await _ref
        .read(saveScaleSingleChoiceAnswerUseCaseProvider)
        .execute(
          sessionId: _args.sessionId,
          questionId: questionId,
          optionId: optionId,
        );

    final finalSavingIds = Set<int>.from(state.savingQuestionIds)
      ..remove(questionId);
    switch (result) {
      case Failure<bool>(error: final error):
        state = state.copyWith(
          singleChoiceAnswers: previousAnswers,
          unansweredRequiredQuestionIds: previousUnanswered,
          savingQuestionIds: finalSavingIds,
          errorMessage: error.message,
        );
        return;
      case Success<bool>():
        state = state.copyWith(savingQuestionIds: finalSavingIds);
        return;
    }
  }

  void goNextQuestion() {
    final questions = _questions;
    if (questions.isEmpty) return;
    final maxIndex = questions.length - 1;
    if (state.currentQuestionIndex >= maxIndex) return;
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
  }

  void goPreviousQuestion() {
    if (state.currentQuestionIndex <= 0) return;
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex - 1,
    );
  }

  void jumpToQuestion(int index) {
    final questions = _questions;
    if (index < 0 || index >= questions.length) return;
    if (index == state.currentQuestionIndex) return;
    state = state.copyWith(currentQuestionIndex: index);
  }

  int? firstUnansweredRequiredIndex() {
    final questions = _questions;
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      if (!question.required) continue;
      final answered = state.singleChoiceAnswers.containsKey(
        question.questionId,
      );
      if (!answered) return i;
    }
    return null;
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final firstUnansweredIndex = firstUnansweredRequiredIndex();
    if (firstUnansweredIndex != null) {
      state = state.copyWith(
        currentQuestionIndex: firstUnansweredIndex,
        errorMessage: '请先完成所有必答题',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final result = await _ref
        .read(submitScaleSessionUseCaseProvider)
        .execute(sessionId: _args.sessionId);

    switch (result) {
      case Failure<bool>(error: final error):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        );
        return;
      case Success<bool>():
        state = state.copyWith(
          isSubmitting: false,
          submittedSessionId: _args.sessionId,
        );
        return;
    }
  }

  void clearSubmitted() {
    state = state.copyWith(submittedSessionId: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  List<ScaleQuestion> get _questions {
    return state.detail?.questions ?? const <ScaleQuestion>[];
  }

  Map<int, int> _buildSingleChoiceAnswerMap(List<ScaleAnswer> answers) {
    final map = <int, int>{};
    for (final answer in answers) {
      final optionId = answer.selectedOptionId;
      if (optionId == null) continue;
      map[answer.questionId] = optionId;
    }
    return map;
  }

  int _findInitialQuestionIndex(
    List<ScaleQuestion> questions,
    Map<int, int> answers,
  ) {
    if (questions.isEmpty) return 0;
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      if (question.required && !answers.containsKey(question.questionId)) {
        return i;
      }
    }
    return 0;
  }
}
