import 'package:flutter/widgets.dart';

enum RouteAction { push, pop }

typedef RouteListener =
    void Function(RouteSettings settings, RouteAction action);

final class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver._();

  static final instance = AppRouteObserver._();
  static final _stack = <RouteSettings>[];
  static final listeners = <RouteListener>[];

  static RouteSettings? get current => _stack.isEmpty ? null : _stack.last;

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route is! PageRoute) return;
    _stack.add(route.settings);
    for (final listener in listeners) {
      listener(route.settings, RouteAction.push);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route is! PageRoute) return;
    _stack.remove(route.settings);
    for (final listener in listeners) {
      listener(route.settings, RouteAction.pop);
    }
  }
}
