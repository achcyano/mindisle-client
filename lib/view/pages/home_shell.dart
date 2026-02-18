import 'package:flutter/material.dart';
import 'package:mindisle_client/view/pages/home/profile_page.dart';
import 'package:mindisle_client/view/pages/home/home_page/home_page.dart';
import 'package:mindisle_client/view/pages/home/medicine_page.dart';
import 'package:mindisle_client/view/pages/home/chat_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static final route = AppRoute<void>(
    path: '/',
    builder: (_) => const HomeShell(),
  );

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );
  int _currentIndex = 0;

  late final List<WidgetBuilder> _tabRootBuilders = <WidgetBuilder>[
    (_) => HomePage(onRouteRequested: _onRouteRequested),
    (_) => const ChatPage(),
    (_) => const MedicinePage(),
    (_) => const ProfilePage(),
  ];
  late final List<String> _tabRootRouteNames = <String>[
    '/home/home',
    '/home/chat',
    '/home/medicine',
    ProfilePage.route.path,
  ];

  Future<void> _handleBackPressed() async {
    final currentNavigator = _tabNavigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && await currentNavigator.maybePop()) {
      return;
    }

    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _onRouteRequested(AppRouteBase route) {
    final targetIndex = _tabRootRouteNames.indexOf(route.path);
    if (targetIndex < 0) {
      return;
    }

    _onDestinationSelected(targetIndex);
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) {
      _tabNavigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildTabNavigator(int index) {
    final routeName = _tabRootRouteNames[index];

    return Offstage(
      offstage: _currentIndex != index,
      child: TickerMode(
        enabled: _currentIndex == index,
        child: Navigator(
          key: _tabNavigatorKeys[index],
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              settings: settings.name == null
                  ? RouteSettings(name: routeName)
                  : settings,
              builder: _tabRootBuilders[index],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        body: Stack(
          children: List<Widget>.generate(4, _buildTabNavigator),
        ),
        bottomNavigationBar: NavigationBar(
          key: const ValueKey('home_shell_navigation_bar'),
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_filled),
              label: '主页',
            ),
            NavigationDestination(
              icon: Icon(Icons.messenger_outline),
              selectedIcon: Icon(Icons.messenger),
              label: '聊天',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services),
              label: '用药',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '个人资料',
            ),
          ],
        ),
      ),
    );
  }
}
