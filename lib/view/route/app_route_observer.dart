import 'package:flutter/widgets.dart';

enum RouteAction { push, pop }

typedef RouteListener = void Function(
    RouteSettings settings,
    RouteAction action,
    );

final class AppRouteObserver extends NavigatorObserver {
  static final instance = AppRouteObserver._();
  AppRouteObserver._();

  static final _stack = <RouteSettings>[];
  static RouteSettings? get current =>
      _stack.isEmpty ? null : _stack.last;

  static final listeners = <RouteListener>[];

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route is PageRoute) {
      _stack.add(route.settings);
      for (final l in listeners) {
        l(route.settings, RouteAction.push);
      }
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route is PageRoute) {
      _stack.remove(route.settings);
      for (final l in listeners) {
        l(route.settings, RouteAction.pop);
      }
    }
  }
}
