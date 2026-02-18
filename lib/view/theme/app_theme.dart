import 'package:flutter/material.dart';
import 'package:mindisle_client/view/theme/app_text_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      textTheme: AppTextTheme.build(base.textTheme),
      navigationBarTheme: const NavigationBarThemeData(
        height: 64,
      ),
    );
  }
}
