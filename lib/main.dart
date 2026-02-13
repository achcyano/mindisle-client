import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/data/preference/hive_pref_tool.dart';
import 'package:mindisle_client/shared/session/session_expired_signal.dart';
import 'package:mindisle_client/view/pages/login/login_page.dart';
import 'package:mindisle_client/view/pages/start/launch_page.dart';
import 'package:mindisle_client/view/route/app_navigator.dart';
import 'package:mindisle_client/view/route/app_route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HivePrefTool.instance.init(boxName: 'app_preferences');
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(sessionExpiredTickProvider, (previous, next) {
      if (next == previous) return;

      final navContext = AppNavigator.key.currentContext;
      if (navContext == null) return;

      LoginPage.route.replace(navContext);

      final messenger = AppNavigator.scaffoldMessengerKey.currentState;
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('账号信息已过期，请重新登录'),
        ),
      );
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      navigatorKey: AppNavigator.key,
      scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
      navigatorObservers: [AppRouteObserver.instance],
      home: const LaunchPage(),
    );
  }
}
