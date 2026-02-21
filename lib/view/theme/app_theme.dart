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
    final thinChipBorder = BorderSide(
      width: 0.5,
      color: swappedScheme.outlineVariant.withValues(alpha: 0.75),
    );
    return base.copyWith(
      colorScheme: swappedScheme,
      scaffoldBackgroundColor: swappedScheme.surface,
      textTheme: AppTextTheme.build(base.textTheme),
      chipTheme: base.chipTheme.copyWith(
        side: thinChipBorder,
        shape: StadiumBorder(side: thinChipBorder),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: swappedScheme.surfaceContainer,
      ),
    );
  }
}
