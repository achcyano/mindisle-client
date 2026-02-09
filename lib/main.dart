import 'package:flutter/material.dart';
import 'package:mindisle_client/data/storage/hive_pref_tool.dart';
import 'core/app_navigator.dart';
import 'core/app_route_observer.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  await HivePrefTool.instance.init(boxName: 'app_preferences');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.key,
      navigatorObservers: [AppRouteObserver.instance],
      home: const HomePage(),
    );
  }
}
