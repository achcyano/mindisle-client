import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_codec.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
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
            final answerDrafts = ScaleAnswerCodec.fromSessionAnswers(
              answers: sessionDetail.answers,
              questions: detail.questions,
            );
            final initialIndex = _findInitialQuestionIndex(
              questions: detail.questions,
              answerDrafts: answerDrafts,
              unansweredRequiredQuestionIds:
                  sessionDetail.unansweredRequiredQuestionIds,
            );
            state = state.copyWith(
              isLoading: false,
              detail: detail,
              session: sessionDetail.session,
              answerDrafts: answerDrafts,
              unansweredRequiredQuestionIds:
                  sessionDetail.unansweredRequiredQuestionIds,
              currentQuestionIndex: initialIndex,
            );
            return;
        }
    }
  }

  Future<void> updateDraft({
    required ScaleQuestion question,
    required ScaleAnswerDraft draft,
    bool saveNow = false,
  }) async {
    if (state.isSubmitting) return;
    if (state.savingQuestionIds.contains(question.questionId)) return;

    final previousDraft = state.answerDrafts[question.questionId];
    final nextDraft = draft.copyWith(isDirty: !saveNow);
    _setDraft(question: question, draft: nextDraft);

    if (!saveNow) return;
    await _saveQuestion(question: question, rollbackDraft: previousDraft);
  }

  Future<void> goNextQuestion() async {
    final questions = _questions;
    if (questions.isEmpty) return;
    final current = _currentQuestion;
    if (current != null) {
      await _persistQuestionIfDirty(current);
    }

    final maxIndex = questions.length - 1;
    if (state.currentQuestionIndex >= maxIndex) return;
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
  }

  Future<void> goPreviousQuestion() async {
    final current = _currentQuestion;
    if (current != null) {
      await _persistQuestionIfDirty(current);
    }

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
      final answered = ScaleAnswerCodec.isAnswered(
        question: question,
        draft: state.answerDrafts[question.questionId],
      );
      if (!answered) return i;
    }
    return null;
  }

  Future<bool> persistCurrentQuestionIfDirty() async {
    final current = _currentQuestion;
    if (current == null) return true;
    return _persistQuestionIfDirty(current);
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final persisted = await _persistAllDirtyAnswers();
    if (!persisted) return;

    final firstUnansweredIndex = firstUnansweredRequiredIndex();
    if (firstUnansweredIndex != null) {
      state = state.copyWith(
        currentQuestionIndex: firstUnansweredIndex,
        errorMessage: '璇峰厛瀹屾垚鎵€鏈夊繀绛旈',
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

  ScaleQuestion? get _currentQuestion {
    final questions = _questions;
    if (questions.isEmpty) return null;
    final index = state.currentQuestionIndex.clamp(0, questions.length - 1);
    return questions[index];
  }

  void _setDraft({
    required ScaleQuestion question,
    required ScaleAnswerDraft draft,
  }) {
    final nextDrafts = Map<int, ScaleAnswerDraft>.from(state.answerDrafts);
    nextDrafts[question.questionId] = draft;
    final unansweredRequiredQuestionIds = _mergeUnansweredRequired(
      base: state.unansweredRequiredQuestionIds,
      question: question,
      draft: draft,
    );

    state = state.copyWith(
      answerDrafts: nextDrafts,
      unansweredRequiredQuestionIds: unansweredRequiredQuestionIds,
      errorMessage: null,
    );
  }

  Future<bool> _persistAllDirtyAnswers() async {
    for (final question in _questions) {
      final ok = await _persistQuestionIfDirty(question);
      if (!ok) return false;
    }
    return true;
  }

  Future<bool> _persistQuestionIfDirty(ScaleQuestion question) async {
    final draft = state.answerDrafts[question.questionId];
    if (draft == null || !draft.isDirty) return true;
    return _saveQuestion(question: question, rollbackDraft: draft);
  }

  Future<bool> _saveQuestion({
    required ScaleQuestion question,
    required ScaleAnswerDraft? rollbackDraft,
  }) async {
    final questionId = question.questionId;
    if (state.isSubmitting || state.savingQuestionIds.contains(questionId)) {
      return false;
    }

    final draft = state.answerDrafts[questionId];
    final answer = ScaleAnswerCodec.toRequestAnswer(
      question: question,
      draft: draft,
    );

    if (answer == null) {
      if (draft == null) {
        return true;
      }
      final nextDrafts = Map<int, ScaleAnswerDraft>.from(state.answerDrafts);
      nextDrafts[questionId] = draft.copyWith(isDirty: false);
      final unansweredRequiredQuestionIds = _mergeUnansweredRequired(
        base: state.unansweredRequiredQuestionIds,
        question: question,
        draft: nextDrafts[questionId],
      );
      state = state.copyWith(
        answerDrafts: nextDrafts,
        unansweredRequiredQuestionIds: unansweredRequiredQuestionIds,
      );
      return true;
    }

    final savingQuestionIds = Set<int>.from(state.savingQuestionIds)
      ..add(questionId);
    state = state.copyWith(
      savingQuestionIds: savingQuestionIds,
      errorMessage: null,
    );

    final result = await _ref.read(saveScaleAnswerUseCaseProvider).execute(
      sessionId: _args.sessionId,
      questionId: questionId,
      answer: answer,
    );

    final finalSavingIds = Set<int>.from(state.savingQuestionIds)
      ..remove(questionId);

    switch (result) {
      case Failure<bool>(error: final error):
        final rollbackMap = Map<int, ScaleAnswerDraft>.from(state.answerDrafts);
        if (rollbackDraft == null) {
          rollbackMap.remove(questionId);
        } else {
          rollbackMap[questionId] = rollbackDraft;
        }
        final unansweredRequiredQuestionIds = _mergeUnansweredRequired(
          base: state.unansweredRequiredQuestionIds,
          question: question,
          draft: rollbackMap[questionId],
        );
        state = state.copyWith(
          answerDrafts: rollbackMap,
          savingQuestionIds: finalSavingIds,
          unansweredRequiredQuestionIds: unansweredRequiredQuestionIds,
          errorMessage: error.message,
        );
        return false;
      case Success<bool>():
        final nextDrafts = Map<int, ScaleAnswerDraft>.from(state.answerDrafts);
        final currentDraft = nextDrafts[questionId];
        if (currentDraft != null) {
          nextDrafts[questionId] = currentDraft.copyWith(isDirty: false);
        }
        final unansweredRequiredQuestionIds = _mergeUnansweredRequired(
          base: state.unansweredRequiredQuestionIds,
          question: question,
          draft: nextDrafts[questionId],
        );
        state = state.copyWith(
          answerDrafts: nextDrafts,
          savingQuestionIds: finalSavingIds,
          unansweredRequiredQuestionIds: unansweredRequiredQuestionIds,
        );
        return true;
    }
  }

  List<int> _mergeUnansweredRequired({
    required List<int> base,
    required ScaleQuestion question,
    required ScaleAnswerDraft? draft,
  }) {
    final next = <int>{...base}..remove(question.questionId);
    final isAnswered = ScaleAnswerCodec.isAnswered(
      question: question,
      draft: draft,
    );
    if (question.required && !isAnswered) {
      next.add(question.questionId);
    }
    final sorted = next.toList(growable: false)..sort();
    return sorted;
  }

  int _findInitialQuestionIndex({
    required List<ScaleQuestion> questions,
    required Map<int, ScaleAnswerDraft> answerDrafts,
    required List<int> unansweredRequiredQuestionIds,
  }) {
    if (questions.isEmpty) return 0;

    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      if (!question.required) continue;
      final isAnswered = ScaleAnswerCodec.isAnswered(
        question: question,
        draft: answerDrafts[question.questionId],
      );
      if (!isAnswered) return i;
    }

    if (unansweredRequiredQuestionIds.isNotEmpty) {
      for (var i = 0; i < questions.length; i++) {
        if (unansweredRequiredQuestionIds.contains(questions[i].questionId)) {
          return i;
        }
      }
    }

    return 0;
  }
}
