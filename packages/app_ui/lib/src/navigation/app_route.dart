import 'package:app_ui/src/navigation/app_route_observer.dart';
import 'package:flutter/material.dart';

typedef RouteMiddleware<T> = bool Function(BuildContext context, T route);

abstract class AppRouteBase {
  const AppRouteBase({required this.path});

  final String path;

  RouteSettings get settings => RouteSettings(name: path);

  bool get alreadyIn => AppRouteObserver.current?.name == path;
}

final class AppRoute<Ret> extends AppRouteBase {
  const AppRoute({
    required super.path,
    required this.builder,
    this.middlewares = const [],
  });

  final WidgetBuilder builder;
  final List<RouteMiddleware<AppRoute<Ret>>> middlewares;

  Future<Ret?> go(BuildContext context) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(
      context,
    ).push<Ret>(MaterialPageRoute(settings: settings, builder: builder));
  }

  Future<Ret?> goRoot(BuildContext context) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(
      context,
      rootNavigator: true,
    ).push<Ret>(MaterialPageRoute(settings: settings, builder: builder));
  }

  Future<Ret?> replace(BuildContext context) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(context).pushReplacement<Ret, dynamic>(
      MaterialPageRoute(settings: settings, builder: builder),
    );
  }

  Future<Ret?> replaceRoot(BuildContext context) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacement<Ret, dynamic>(
      MaterialPageRoute(settings: settings, builder: builder),
    );
  }
}

final class AppRouteArg<Ret, Arg extends Object> extends AppRouteBase {
  const AppRouteArg({
    required super.path,
    required this.builder,
    this.middlewares = const [],
  });

  final Widget Function(Arg arg) builder;
  final List<RouteMiddleware<AppRouteArg<Ret, Arg>>> middlewares;

  Future<Ret?> go(BuildContext context, Arg arg) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(context).push<Ret>(
      MaterialPageRoute(settings: settings, builder: (_) => builder(arg)),
    );
  }

  Future<Ret?> goRoot(BuildContext context, Arg arg) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(context, rootNavigator: true).push<Ret>(
      MaterialPageRoute(settings: settings, builder: (_) => builder(arg)),
    );
  }

  Future<Ret?> replace(BuildContext context, Arg arg) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(context).pushReplacement<Ret, dynamic>(
      MaterialPageRoute(settings: settings, builder: (_) => builder(arg)),
    );
  }

  Future<Ret?> replaceRoot(BuildContext context, Arg arg) {
    if (middlewares.any((middleware) => !middleware(context, this))) {
      return Future.value(null);
    }

    return Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacement<Ret, dynamic>(
      MaterialPageRoute(settings: settings, builder: (_) => builder(arg)),
    );
  }
}
