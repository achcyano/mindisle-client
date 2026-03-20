import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:app_ui/app_ui.dart';
import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/core/static.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_controller.dart';
import 'package:doctor/shared/session/session_expired_signal.dart';
import 'package:doctor/view/pages/auth/login_page.dart';
import 'package:doctor/view/pages/start/launch_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HivePrefTool.instance.init(boxName: 'doctor_preferences');
  runApp(const ProviderScope(child: DoctorApp()));
}

class DoctorApp extends ConsumerWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(sessionExpiredTickProvider, (previous, next) {
      if (next == previous) return;

      unawaited(() async {
        final navContext = AppNavigator.key.currentContext;
        final navigator = AppNavigator.key.currentState;
        if (navContext == null || navigator == null) return;

        final mediaQuery = MediaQuery.maybeOf(navContext);
        final safeBottom = mediaQuery?.padding.bottom ?? 0;
        final viewInsetsBottom = mediaQuery?.viewInsets.bottom ?? 0;
        final bottomMargin = viewInsetsBottom > 0
            ? 16 + safeBottom + viewInsetsBottom
            : 236 + safeBottom;

        await ref.read(sessionStoreProvider).clearSession();
        ref.read(doctorAuthControllerProvider.notifier).clearSession();

        if (!navigator.mounted) return;
        await navigator.pushReplacement<void, void>(
          MaterialPageRoute<void>(
            settings: DoctorLoginPage.route.settings,
            builder: DoctorLoginPage.route.builder,
          ),
        );

        final messenger = AppNavigator.scaffoldMessengerKey.currentState;
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
            content: const Text('账号信息已过期，请重新登录'),
          ),
        );
      }());
    });

    return MaterialApp(
      navigatorKey: AppNavigator.key,
      scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
      navigatorObservers: <NavigatorObserver>[AppRouteObserver.instance],
      title: "$appDisplayName医生端",
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const <Locale>[Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: const DoctorLaunchPage(),
    );
  }
}
