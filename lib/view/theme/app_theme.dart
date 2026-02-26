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
      iconTheme: base.iconTheme.copyWith(color: swappedScheme.onSurface),
      primaryIconTheme: base.primaryIconTheme.copyWith(
        color: swappedScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: swappedScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: thinChipBorder,
        shape: StadiumBorder(side: thinChipBorder),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: swappedScheme.surfaceContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: swappedScheme.surfaceContainerHighest,
        elevation: 0,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: swappedScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: swappedScheme.surfaceContainerLow,
        insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        constraints: const BoxConstraints(maxWidth: 640),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTextTheme.build(base.textTheme).bodyMedium,
        subtitleTextStyle: AppTextTheme.build(base.textTheme).bodySmall
            ?.copyWith(color: swappedScheme.onSurface.withValues(alpha: 0.6)),
        leadingAndTrailingTextStyle: AppTextTheme.build(
          base.textTheme,
        ).labelMedium,
        iconColor: swappedScheme.onSurfaceVariant,
      ),
    );
  }
}
