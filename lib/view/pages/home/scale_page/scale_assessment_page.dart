import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_assessment_args.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_assessment_controller.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_assessment_state.dart';
import 'package:mindisle_client/view/pages/home/scale_page/scale_result_page.dart';
import 'package:mindisle_client/view/pages/home/scale_page/widgets/question_step_card.dart';
import 'package:mindisle_client/view/pages/home/scale_page/widgets/scale_assist_bottom_sheet.dart';
import 'package:mindisle_client/view/pages/home/scale_page/widgets/scale_progress_header.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class ScaleAssessmentPage extends ConsumerStatefulWidget {
  const ScaleAssessmentPage({super.key, required this.args});

  final ScaleAssessmentArgs args;

  static final route = AppRouteArg<void, ScaleAssessmentArgs>(
    path: '/home/scale/assessment',
    builder: (args) => ScaleAssessmentPage(args: args),
  );

  @override
  ConsumerState<ScaleAssessmentPage> createState() =>
      _ScaleAssessmentPageState();
}

class _ScaleAssessmentPageState extends ConsumerState<ScaleAssessmentPage> {
  ScaleAssessmentArgs get _args => widget.args;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.initialize();
    });
  }

  ScaleAssessmentController get _controller =>
      ref.read(scaleAssessmentControllerProvider(_args).notifier);

  @override
  Widget build(BuildContext context) {
    _listenStateChanges(context);

    final state = ref.watch(scaleAssessmentControllerProvider(_args));
    final data = _AssessmentViewData.fromState(state);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(data.detail?.name ?? '量表作答'),
      ),
      floatingActionButton: _buildPrimaryFab(state: state, data: data),
      body: SafeArea(
        top: false,
        child: _buildBody(context: context, state: state, data: data),
      ),
    );
  }

  void _listenStateChanges(BuildContext context) {
    ref.listen<ScaleAssessmentState>(scaleAssessmentControllerProvider(_args), (
      previous,
      next,
    ) {
      _maybeHandleError(context, previous, next);
      _maybeHandleSubmitted(context, previous, next);
    });
  }

  void _maybeHandleError(
    BuildContext context,
    ScaleAssessmentState? previous,
    ScaleAssessmentState next,
  ) {
    final message = next.errorMessage;
    if (message == null || message.isEmpty) return;
    if (message == previous?.errorMessage) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
    _controller.clearError();
  }

  void _maybeHandleSubmitted(
    BuildContext context,
    ScaleAssessmentState? previous,
    ScaleAssessmentState next,
  ) {
    final submittedSessionId = next.submittedSessionId;
    if (submittedSessionId == null) return;
    if (submittedSessionId == previous?.submittedSessionId) return;
    if (!mounted) return;

    _controller.clearSubmitted();
    unawaited(ScaleResultPage.route.replace(context, submittedSessionId));
  }

  Widget? _buildPrimaryFab({
    required ScaleAssessmentState state,
    required _AssessmentViewData data,
  }) {
    if (!data.hasQuestion) return null;

    return FloatingActionButton.extended(
      onPressed: state.isSubmitting
          ? null
          : () {
              if (data.isLastQuestion) {
                _controller.submit();
              } else {
                _controller.goNextQuestion();
              }
            },
      icon: state.isSubmitting
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(data.isLastQuestion ? Icons.check : Icons.arrow_forward),
      label: Text(
        _primaryFabLabel(state: state, isLastQuestion: data.isLastQuestion),
      ),
    );
  }

  String _primaryFabLabel({
    required ScaleAssessmentState state,
    required bool isLastQuestion,
  }) {
    if (isLastQuestion) {
      return state.isSubmitting ? '提交中...' : '提交量表';
    }
    return '下一题';
  }

  Widget _buildBody({
    required BuildContext context,
    required ScaleAssessmentState state,
    required _AssessmentViewData data,
  }) {
    if (state.isLoading && data.detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.detail == null) {
      return _buildRetry();
    }
    return _buildAssessmentContent(context: context, state: state, data: data);
  }

  Widget _buildRetry() {
    return Center(
      child: FilledButton(
        onPressed: _controller.initialize,
        child: const Text('重试'),
      ),
    );
  }

  Widget _buildAssessmentContent({
    required BuildContext context,
    required ScaleAssessmentState state,
    required _AssessmentViewData data,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: ScaleProgressHeader(
            currentIndex: data.index,
            total: data.questionCount,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data.currentQuestion != null)
                  _buildQuestionCard(
                    context: context,
                    state: state,
                    question: data.currentQuestion!,
                  ),
                const SizedBox(height: 10),
                Text(
                  '作答将自动保存。AI 建议仅供参考，如有疑问请咨询医生。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
        if (data.hasQuestion)
          _buildBottomBar(state: state, questionCount: data.questionCount),
      ],
    );
  }

  Widget _buildQuestionCard({
    required BuildContext context,
    required ScaleAssessmentState state,
    required ScaleQuestion question,
  }) {
    return QuestionStepCard(
      question: question,
      selectedOptionId: state.singleChoiceAnswers[question.questionId],
      isSaving: state.savingQuestionIds.contains(question.questionId),
      enabled: !state.isSubmitting,
      onSelectOption: (option) {
        final optionId = option.optionId;
        if (optionId == null) return;
        _controller.selectSingleChoice(
          questionId: question.questionId,
          optionId: optionId,
        );
      },
      onAskAi: () {
        _openAssistBottomSheet(context: context, question: question);
      },
    );
  }

  void _openAssistBottomSheet({
    required BuildContext context,
    required ScaleQuestion question,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return ScaleAssistBottomSheet(
          sessionId: _args.sessionId,
          questionId: question.questionId,
          questionStem: question.stem,
        );
      },
    );
  }

  Widget _buildBottomBar({
    required ScaleAssessmentState state,
    required int questionCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: state.currentQuestionIndex <= 0 || state.isSubmitting
                  ? null
                  : _controller.goPreviousQuestion,
              child: const Text('上一题'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '已答 ${state.singleChoiceAnswers.length}/$questionCount',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

final class _AssessmentViewData {
  const _AssessmentViewData({
    required this.detail,
    required this.questionCount,
    required this.hasQuestion,
    required this.index,
    required this.currentQuestion,
    required this.isLastQuestion,
  });

  factory _AssessmentViewData.fromState(ScaleAssessmentState state) {
    final detail = state.detail;
    final questions = detail?.questions ?? const <ScaleQuestion>[];
    final questionCount = questions.length;
    final hasQuestion = questionCount > 0;
    final index = hasQuestion
        ? state.currentQuestionIndex.clamp(0, questionCount - 1)
        : 0;
    final currentQuestion = hasQuestion ? questions[index] : null;
    final isLastQuestion = hasQuestion && index == questionCount - 1;

    return _AssessmentViewData(
      detail: detail,
      questionCount: questionCount,
      hasQuestion: hasQuestion,
      index: index,
      currentQuestion: currentQuestion,
      isLastQuestion: isLastQuestion,
    );
  }

  final ScaleDetail? detail;
  final int questionCount;
  final bool hasQuestion;
  final int index;
  final ScaleQuestion? currentQuestion;
  final bool isLastQuestion;
}
