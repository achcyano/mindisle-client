import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/result/app_error.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/core/static.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/features/event/presentation/home/event_home_controller.dart';
import 'package:patient/features/event/presentation/home/event_home_state.dart';
import 'package:patient/features/medication/presentation/list/medication_list_controller.dart';
import 'package:patient/features/medication/presentation/list/medication_list_state.dart';
import 'package:patient/features/scale/domain/entities/scale_entities.dart';
import 'package:patient/features/scale/presentation/assessment/scale_assessment_args.dart';
import 'package:patient/features/scale/presentation/providers/scale_providers.dart';
import 'package:patient/features/user/presentation/providers/user_providers.dart';
import 'package:patient/shared/session/startup_network_issue_signal.dart';
import 'package:patient/view/pages/chat/chat_page.dart';
import 'package:patient/view/pages/home/card_home.dart';
import 'package:patient/view/pages/home/home_event_card.dart';
import 'package:patient/view/pages/home/startup_network_error_card.dart';
import 'package:patient/view/pages/home/today_medication_card.dart';
import 'package:patient/view/pages/home/today_mood_card.dart';
import 'package:patient/view/pages/info/info_page.dart';
import 'package:patient/view/pages/login/login_page.dart';
import 'package:patient/view/pages/medicine/medicine_page.dart';
import 'package:patient/view/pages/profile/profile_page.dart';
import 'package:patient/view/pages/scale/scale_assessment_page.dart';
import 'package:patient/view/pages/scale/scale_list_page.dart';
import 'package:patient/view/route/app_route.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.onRouteRequested});

  final void Function(AppRouteBase route) onRouteRequested;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isRetryingStartupIssue = false;
  int? _lastSnackIssueId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(eventHomeControllerProvider.notifier).initialize();
      ref.read(medicationListControllerProvider.notifier).initialize();
    });
  }

  Future<void> _retryStartupIssue() async {
    if (_isRetryingStartupIssue) return;

    setState(() {
      _isRetryingStartupIssue = true;
    });

    try {
      final result = await ref.read(getMeUseCaseProvider).execute();
      if (!mounted) return;

      switch (result) {
        case Success():
          ref.read(startupNetworkIssueProvider.notifier).state = null;
          return;
        case Failure(error: final error):
          if (error.type == AppErrorType.unauthorized) {
            ref.read(startupNetworkIssueProvider.notifier).state = null;
            await LoginPage.route.replaceRoot(context);
            return;
          }

          if (error.type == AppErrorType.network) {
            ref
                .read(startupNetworkIssueProvider.notifier)
                .state = StartupNetworkIssue(
              message: error.message.isEmpty
                  ? '网络连接失败，请检查网络后重试'
                  : error.message,
              issueId: DateTime.now().microsecondsSinceEpoch,
              isNetwork: true,
            );
            return;
          }

          ref
              .read(startupNetworkIssueProvider.notifier)
              .state = StartupNetworkIssue(
            message: error.message.isEmpty ? '请求失败，请稍后重试' : error.message,
            issueId: DateTime.now().microsecondsSinceEpoch,
            isNetwork: false,
            showSnackBar: true,
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetryingStartupIssue = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StartupNetworkIssue?>(startupNetworkIssueProvider, (
      previous,
      next,
    ) {
      if (next == null || !next.showSnackBar) return;
      if (_lastSnackIssueId == next.issueId) return;
      _lastSnackIssueId = next.issueId;

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(next.message)));
    });

    final startupIssue = ref.watch(startupNetworkIssueProvider);
    ref.listen<EventHomeState>(eventHomeControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      if (message == previous?.errorMessage) return;

      _showSnack(message);
      ref.read(eventHomeControllerProvider.notifier).clearError();
    });
    final eventState = ref.watch(eventHomeControllerProvider);
    final medicationState = ref.watch(medicationListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.home_outlined),
        title: const Text(appDisplayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              widget.onRouteRequested(ProfilePage.route);
            },
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 8,
              children: [
                if (startupIssue != null)
                  StartupNetworkErrorCard(
                    title: startupIssue.isNetwork ? '网络连接异常' : '请求失败',
                    message: startupIssue.message,
                    isRetrying: _isRetryingStartupIssue,
                    onRetry: _retryStartupIssue,
                  ),
                ..._buildEventCards(eventState),
                _buildTodayMedicationCard(
                  medicationState,
                  suppressErrorCard: startupIssue != null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: HomeActionCard(
                        icon: Icons.assessment_outlined,
                        title: '量表评估',
                        onTap: () {
                          ScaleListPage.route.goRoot(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: HomeActionCard(
                        icon: Icons.messenger_outline,
                        title: '聊天',
                        onTap: () {
                          ChatPage.route.goRoot(context);
                        },
                      ),
                    ),
                  ],
                ),
                const TodayMoodCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEventCards(EventHomeState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const [
        Card(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ];
    }

    if (state.items.isEmpty) return const <Widget>[];

    return <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('待办事项', style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
      for (final item in state.items)
        HomeEventCard(
          item: item,
          onTap: () {
            _handleEventTap(item);
          },
        ),
    ];
  }

  Widget _buildTodayMedicationCard(
    MedicationListState state, {
    required bool suppressErrorCard,
  }) {
    return TodayMedicationCard(
      items: state.activeItems,
      isLoading: state.isLoading || !state.initialized,
      errorMessage: suppressErrorCard ? null : state.errorMessage,
      onTapManage: () {
        widget.onRouteRequested(MedicinePage.route);
      },
      onRetry: () {
        ref.read(medicationListControllerProvider.notifier).refresh();
      },
    );
  }

  Future<void> _handleEventTap(UserEventItem item) async {
    switch (item.eventType) {
      case UserEventType.openScale:
        await _openScaleEvent(item);
        return;
      case UserEventType.continueScaleSession:
        await _continueScaleEvent(item);
        return;
      case UserEventType.importMedicationPlan:
        widget.onRouteRequested(MedicinePage.route);
        return;
      case UserEventType.updateBasicProfile:
        await InfoPage.route.goRoot(context);
        if (!mounted) return;
        await ref.read(eventHomeControllerProvider.notifier).refresh();
        return;
      case UserEventType.bindDoctor:
        // TODO(hztcm): wire up doctor binding flow and update status.
        return;
      case UserEventType.unknown:
        return;
    }
  }

  Future<void> _openScaleEvent(UserEventItem item) async {
    final scaleId = item.scaleId;
    if (scaleId == null || scaleId <= 0) {
      await ScaleListPage.route.goRoot(context);
      if (!mounted) return;
      await ref.read(eventHomeControllerProvider.notifier).refresh();
      return;
    }

    final result = await ref
        .read(createOrResumeScaleSessionUseCaseProvider)
        .execute(scaleId: scaleId);

    switch (result) {
      case Failure<ScaleCreateSessionResult>(error: final error):
        _showSnack(error.message);
        return;
      case Success<ScaleCreateSessionResult>(data: final data):
        if (!mounted) return;
        await ScaleAssessmentPage.route.goRoot(
          context,
          ScaleAssessmentArgs(scaleId: scaleId, sessionId: data.session.sessionId),
        );
        if (!mounted) return;
        await ref.read(eventHomeControllerProvider.notifier).refresh();
        return;
    }
  }

  Future<void> _continueScaleEvent(UserEventItem item) async {
    final scaleId = item.scaleId;
    final sessionId = item.sessionId;

    if (scaleId == null || scaleId <= 0 || sessionId == null || sessionId <= 0) {
      await ScaleListPage.route.goRoot(context);
      if (!mounted) return;
      await ref.read(eventHomeControllerProvider.notifier).refresh();
      return;
    }

    await ScaleAssessmentPage.route.goRoot(
      context,
      ScaleAssessmentArgs(scaleId: scaleId, sessionId: sessionId),
    );
    if (!mounted) return;
    await ref.read(eventHomeControllerProvider.notifier).refresh();
  }

  Future<void> _onPullToRefresh() async {
    final startupIssue = ref.read(startupNetworkIssueProvider);
    if (startupIssue != null) {
      await _retryStartupIssue();
    }

    if (!mounted) return;
    await Future.wait([
      ref.read(eventHomeControllerProvider.notifier).refresh(),
      ref.read(medicationListControllerProvider.notifier).refresh(),
    ]);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
