import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/app_error.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/data/preference/const.dart';
import 'package:mindisle_client/features/user/presentation/providers/user_providers.dart';
import 'package:mindisle_client/view/pages/home_shell.dart';
import 'package:mindisle_client/view/pages/login/login_page.dart';
import 'package:mindisle_client/view/pages/start/welcome_page.dart';
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

    final result = await ref.read(getMeUseCaseProvider).execute();
    if (!mounted) return;

    switch (result) {
      case Success():
        await AppPrefs.hasCompletedFirstLogin.set(true);
        if (!mounted) return;
        await HomeShell.route.replace(context);
        return;
      case Failure(error: final error):
        if (error.type == AppErrorType.unauthorized) {
          await LoginPage.route.replace(context);
        } else {
          await HomeShell.route.replace(context);
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicatorM3E(),
      ),
    );
  }
}
