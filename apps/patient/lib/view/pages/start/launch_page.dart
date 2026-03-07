import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/result/app_error.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/core/providers/app_providers.dart';
import 'package:patient/data/preference/const.dart';
import 'package:patient/features/medication/presentation/list/medication_list_controller.dart';
import 'package:patient/features/user/presentation/profile/profile_completion_guard.dart';
import 'package:patient/features/user/presentation/providers/user_providers.dart';
import 'package:patient/shared/session/startup_network_issue_signal.dart';
import 'package:patient/view/pages/home_shell.dart';
import 'package:patient/view/pages/info/info_page.dart';
import 'package:patient/view/pages/login/login_page.dart';
import 'package:patient/view/pages/start/welcome_page.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class LaunchPage extends ConsumerStatefulWidget {
  const LaunchPage({super.key});

  @override
  ConsumerState<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends ConsumerState<LaunchPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    ref.read(startupNetworkIssueProvider.notifier).state = null;

    final sessionStore = ref.read(sessionStoreProvider);
    final session = await sessionStore.readSession();
    if (!mounted) return;

    if (session == null) {
      if (!AppPrefs.hasCompletedFirstLogin.value) {
        await WelcomePage.route.replace(context);
        return;
      }
      await LoginPage.route.replace(context);
      return;
    }

    unawaited(ref.read(basicProfileWarmupServiceProvider).warmUp());
    unawaited(ref.read(avatarWarmupServiceProvider).warmUp());
    unawaited(ref.read(medicationListControllerProvider.notifier).initialize());

    final result = await ref.read(getMeUseCaseProvider).execute();
    if (!mounted) return;

    switch (result) {
      case Success():
        final profileResult = await ref.read(getBasicProfileUseCaseProvider).execute();
        if (!mounted) return;

        switch (profileResult) {
          case Success(data: final profile):
            ref.read(startupNetworkIssueProvider.notifier).state = null;
            final isComplete = isBasicProfileComplete(profile);
            await AppPrefs.hasCompletedFirstLogin.set(isComplete);
            if (!mounted) return;

            if (!isComplete) {
              await _goRequiredInfoPage();
              return;
            }
            await HomeShell.route.replace(context);
            return;
          case Failure(error: final error):
            if (error.type == AppErrorType.unauthorized) {
              ref.read(startupNetworkIssueProvider.notifier).state = null;
              await LoginPage.route.replace(context);
              return;
            }

            final cachedProfile = ref
                .read(basicProfileCacheStoreProvider)
                .readForUser(session.principalId);

            if (cachedProfile != null) {
              final isComplete = isBasicProfileComplete(cachedProfile);
              await AppPrefs.hasCompletedFirstLogin.set(isComplete);
              if (!mounted) return;
              if (!isComplete) {
                await _goRequiredInfoPage();
                return;
              }
            } else if (!AppPrefs.hasCompletedFirstLogin.value) {
              await _goRequiredInfoPage();
              return;
            }

            final isNetworkError = error.type == AppErrorType.network;
            final message = error.message.isEmpty
                ? (isNetworkError ? '网络连接失败，请检查网络后重试' : '请求失败，请稍后重试')
                : error.message;

            ref.read(startupNetworkIssueProvider.notifier).state = StartupNetworkIssue(
              message: message,
              issueId: DateTime.now().microsecondsSinceEpoch,
              isNetwork: isNetworkError,
              showSnackBar: !isNetworkError,
            );
            await HomeShell.route.replace(context);
            return;
        }
      case Failure(error: final error):
        if (error.type == AppErrorType.unauthorized) {
          ref.read(startupNetworkIssueProvider.notifier).state = null;
          await LoginPage.route.replace(context);
        } else {
          if (!AppPrefs.hasCompletedFirstLogin.value) {
            await _goRequiredInfoPage();
            return;
          }
          final isNetworkError = error.type == AppErrorType.network;
          final message = error.message.isEmpty
              ? (isNetworkError ? '网络连接失败，请检查网络后重试' : '请求失败，请稍后重试')
              : error.message;

          ref
              .read(startupNetworkIssueProvider.notifier)
              .state = StartupNetworkIssue(
            message: message,
            issueId: DateTime.now().microsecondsSinceEpoch,
            isNetwork: isNetworkError,
            showSnackBar: !isNetworkError,
          );
          await HomeShell.route.replace(context);
        }
        return;
    }
  }

  Future<void> _goRequiredInfoPage() async {
    ref.read(startupNetworkIssueProvider.notifier).state = null;
    await InfoPage.requiredRoute.replace(context);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicatorM3E()));
  }
}
