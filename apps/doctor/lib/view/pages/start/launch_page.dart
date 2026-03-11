import 'package:app_core/app_core.dart';
import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/data/preference/app_prefs.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_controller.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
import 'package:doctor/view/pages/auth/login_page.dart';
import 'package:doctor/view/pages/doctor_shell.dart';
import 'package:doctor/view/pages/start/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorLaunchPage extends ConsumerStatefulWidget {
  const DoctorLaunchPage({super.key});

  @override
  ConsumerState<DoctorLaunchPage> createState() => _DoctorLaunchPageState();
}

class _DoctorLaunchPageState extends ConsumerState<DoctorLaunchPage> {
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
      ref.read(doctorAuthControllerProvider.notifier).clearSession();
      if (!AppPrefs.hasSeenWelcome.value) {
        await DoctorWelcomePage.route.replace(context);
        return;
      }
      await DoctorLoginPage.route.replace(context);
      return;
    }

    final refreshResult = await ref
        .read(doctorRefreshTokenUseCaseProvider)
        .execute();
    if (!mounted) return;

    switch (refreshResult) {
      case Success(data: final data):
        ref.read(doctorAuthControllerProvider.notifier).setSession(data);
        await DoctorShell.route.replace(context);
        return;
      case Failure():
        await sessionStore.clearSession();
        if (!mounted) return;
        ref.read(doctorAuthControllerProvider.notifier).clearSession();
        await DoctorLoginPage.route.replace(context);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
