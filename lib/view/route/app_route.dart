import 'package:flutter/material.dart';
import 'package:mindisle_client/view/route/app_route_observer.dart';

typedef RouteMiddleware<T> = bool Function(
    BuildContext context,
    T route,
    );

abstract class AppRouteBase {
  final String path;
  const AppRouteBase({required this.path});

  RouteSettings get settings => RouteSettings(name: path);

  bool get alreadyIn => AppRouteObserver.current?.name == path;
}


final class AppRoute<Ret> extends AppRouteBase {
  final WidgetBuilder builder;
  final List<RouteMiddleware<AppRoute<Ret>>> middlewares;

  const AppRoute({
    required super.path,
    required this.builder,
    this.middlewares = const [],
  });

  Future<Ret?> go(BuildContext context) {
    if (middlewares.any((m) => !m(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(context).push<Ret>(
      MaterialPageRoute(
        settings: settings,
        builder: builder,
      ),
    );
  }
}

final class AppRouteArg<Ret, Arg extends Object>
    extends AppRouteBase {
  final Widget Function(Arg arg) builder;
  final List<RouteMiddleware<AppRouteArg<Ret, Arg>>> middlewares;

  const AppRouteArg({
    required super.path,
    required this.builder,
    this.middlewares = const [],
  });

  Future<Ret?> go(BuildContext context, Arg arg) {
    if (middlewares.any((m) => !m(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(context).push<Ret>(
      MaterialPageRoute(
        settings: settings,
        builder: (_) => builder(arg),
      ),
    );
  }
}
