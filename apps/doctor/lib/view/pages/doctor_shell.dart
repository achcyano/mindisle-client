import 'package:doctor/view/pages/bindings/bindings_page.dart';
import 'package:doctor/view/pages/me/me_page.dart';
import 'package:doctor/view/pages/patients/patients_page.dart';
import 'package:doctor/view/route/app_route.dart';
import 'package:flutter/material.dart';

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});

  static final route = AppRoute<void>(
    path: '/',
    builder: (_) => const DoctorShell(),
  );

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    3,
    (_) => GlobalKey<NavigatorState>(),
  );

  int _currentIndex = 0;
  late final PageController _pageController = PageController(initialPage: 0);

  late final List<WidgetBuilder> _tabRootBuilders = <WidgetBuilder>[
    (_) => const DoctorPatientsPage(),
    (_) => const DoctorBindingsPage(),
    (_) => const DoctorMePage(),
  ];

  late final List<String> _tabRootRouteNames = <String>[
    DoctorPatientsPage.route.path,
    DoctorBindingsPage.route.path,
    DoctorMePage.route.path,
  ];

  Future<void> _handleBackPressed() async {
    final currentNavigator = _tabNavigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && await currentNavigator.maybePop()) {
      return;
    }

    if (_currentIndex != 0) {
      _onDestinationSelected(0);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) {
      _tabNavigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    final fromIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });

    if (_pageController.hasClients) {
      if ((index - fromIndex).abs() == 1) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _pageController.jumpToPage(index);
      }
    }
  }

  Widget _buildTabNavigator(int index) {
    final routeName = _tabRootRouteNames[index];

    return TickerMode(
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
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tabRootBuilders.length,
          onPageChanged: (index) {
            if (index == _currentIndex) return;
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) => _buildTabNavigator(index),
        ),
        bottomNavigationBar: NavigationBar(
          key: const ValueKey('doctor_shell_navigation_bar'),
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: '患者列表',
            ),
            NavigationDestination(
              icon: Icon(Icons.link_outlined),
              selectedIcon: Icon(Icons.link),
              label: '患者绑定',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
