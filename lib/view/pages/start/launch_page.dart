import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/app_error.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/features/user/presentation/providers/user_providers.dart';
import 'package:mindisle_client/view/pages/home_page.dart';
import 'package:mindisle_client/view/pages/start/login_page.dart';

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
      await LoginPage.route.replace(context);
      return;
    }

    final result = await ref.read(getMeUseCaseProvider).execute();
    if (!mounted) return;

    switch (result) {
      case Success():
        await HomePage.route.replace(context);
      case Failure(error: final error):
        if (error.type == AppErrorType.unauthorized) {
          await LoginPage.route.replace(context);
        } else {
          await HomePage.route.replace(context);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
