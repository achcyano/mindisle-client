import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/data/preference/hive_pref_tool.dart';
import 'package:mindisle_client/view/route/app_navigator.dart';
import 'package:mindisle_client/view/route/app_route_observer.dart';
import 'package:mindisle_client/view/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HivePrefTool.instance.init(boxName: 'app_preferences');
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      navigatorObservers: [AppRouteObserver.instance],
      home: const HomePage(),
    );
  }
}
