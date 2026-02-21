import 'package:flutter/material.dart';
import 'package:mindisle_client/view/theme/app_text_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    final swappedScheme = base.colorScheme.copyWith(
      surface: base.colorScheme.surfaceContainer,
      surfaceContainerLow: base.colorScheme.surface,
    );
    return base.copyWith(
      colorScheme: swappedScheme,
      scaffoldBackgroundColor: swappedScheme.surface,
      textTheme: AppTextTheme.build(base.textTheme),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: swappedScheme.surfaceContainer,
      ),
    );
  }
}
