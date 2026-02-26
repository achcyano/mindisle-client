import 'package:flutter/material.dart';

class AppTextTheme {
  const AppTextTheme._();

  static TextTheme build(TextTheme base) {
    return base.copyWith(
      displaySmall: (base.displaySmall ?? const TextStyle()).copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
      headlineSmall: (base.headlineSmall ?? const TextStyle()).copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
      bodySmall: (base.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 13,
      ),
      bodyMedium: (base.bodyMedium ?? const TextStyle()).copyWith(
        fontSize: 15,
        height: 1.5,
      ),
      titleSmall: (base.titleSmall ?? const TextStyle()).copyWith(
        fontSize: 17,
      ),
      labelSmall: (base.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: (base.labelLarge ?? const TextStyle()).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: (base.titleLarge ?? const TextStyle()).copyWith(
        fontSize: 23,
      ),
      titleMedium: (base.titleMedium ?? const TextStyle()).copyWith(
        fontSize: 16,
        letterSpacing: 0.6,
      ),
    );
  }
}
