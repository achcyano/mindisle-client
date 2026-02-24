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
  bool _allowPop = false;
  bool _isHandlingPop = false;

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

    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePopRequest(context);
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(data.detail?.name ?? '閲忚〃浣滅瓟'),
        ),
        floatingActionButton: _buildPrimaryFab(state: state, data: data),
        body: SafeArea(
          top: false,
          child: _buildBody(context: context, state: state, data: data),
        ),
      ),
    );
  }

  Future<void> _handlePopRequest(BuildContext context) async {
    if (_allowPop || _isHandlingPop) return;
    _isHandlingPop = true;

    final shouldExit = await _showExitConfirmDialog(context);
    _isHandlingPop = false;
    if (!mounted || !shouldExit) return;

    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop();
  }

  Future<bool> _showExitConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('\u9000\u51fa\u7b54\u9898'),
          content: const Text(
            '\u672c\u6b21\u7b54\u9898\u5c06\u4f1a\u88ab\u4fdd\u5b58\uff0c\u540e\u7eed\u53ef\u4ee5\u7ee7\u7eed\u7b54\u9898\u3002',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('\u7ee7\u7eed\u7b54\u9898'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('\u786e\u8ba4\u9000\u51fa'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
      return state.isSubmitting
          ? '\u63d0\u4ea4\u4e2d...'
          : '\u63d0\u4ea4\u91cf\u8868';
    }
    return '\u4e0b\u4e00\u9898';
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
        child: const Text('閲嶈瘯'),
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
                  '\u4f5c\u7b54\u5c06\u81ea\u52a8\u4fdd\u5b58\u3002AI \u5efa\u8bae\u4ec5\u4f9b\u53c2\u8003\uff0c\u5982\u6709\u7591\u95ee\u8bf7\u54a8\u8be2\u533b\u751f\u3002',
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
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
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
              child: const Text('\u4e0a\u4e00\u9898'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '宸茬瓟 ${state.singleChoiceAnswers.length}/$questionCount',
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
