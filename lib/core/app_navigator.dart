import 'package:flutter/widgets.dart';

abstract final class AppNavigator {
  static final key = GlobalKey<NavigatorState>();

  static NavigatorState get state => key.currentState!;
  static BuildContext get context => key.currentContext!;
}
