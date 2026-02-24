import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/app_error.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/features/user/presentation/providers/user_providers.dart';
import 'package:mindisle_client/shared/session/startup_network_issue_signal.dart';
import 'package:mindisle_client/view/pages/home/chat_page/chat_page.dart';
import 'package:mindisle_client/view/pages/home/home_page/card_home.dart';
import 'package:mindisle_client/view/pages/home/home_page/startup_network_error_card.dart';
import 'package:mindisle_client/view/pages/home/home_page/today_mood_card.dart';
import 'package:mindisle_client/view/pages/home/medicine_page.dart';
import 'package:mindisle_client/view/pages/home/profile_page.dart';
import 'package:mindisle_client/view/pages/home/scale_page/scale_list_page.dart';
import 'package:mindisle_client/view/pages/login/login_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.onRouteRequested});

  final void Function(AppRouteBase route) onRouteRequested;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isRetryingStartupIssue = false;
  int? _lastSnackIssueId;

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
            await LoginPage.route.replace(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_outlined, size: 25),
              const SizedBox(width: 8),
              const Text(appDisplayName),
            ],
          ),
        ),
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
        child: SingleChildScrollView(
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
              const HomeActionCard(
                icon: Icons.link,
                title: '绑定医生',
                subtitle: '绑定医生后可使用完整服务',
              ),
              HomeActionCard(
                icon: Icons.medical_services_outlined,
                title: '导入用药计划',
                subtitle: '可使用用药提醒等功能',
                onTap: () {
                  widget.onRouteRequested(MedicinePage.route);
                },
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
    );
  }
}
