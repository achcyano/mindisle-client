import 'package:flutter/material.dart';

abstract final class AppNavigator {
  static final key = GlobalKey<NavigatorState>();
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static NavigatorState get state => key.currentState!;
  static BuildContext get context => key.currentContext!;
}
