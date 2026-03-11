import 'package:flutter/material.dart';

String formatAuthPhone(String value) {
  if (value.isEmpty) return '';
  if (value.length <= 3) return value;
  if (value.length <= 7) {
    return '${value.substring(0, 3)} ${value.substring(3)}';
  }
  return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
}

OutlineInputBorder buildAuthOutlineBorder(
  BuildContext context, {
  bool isError = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(
      color: isError ? colorScheme.error : colorScheme.primary,
      width: 1.2,
    ),
  );
}

void showAuthSnackBar(
  BuildContext context,
  String message, {
  required bool useCustomKeypad,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final mediaQuery = MediaQuery.maybeOf(context);
  final safeBottom = mediaQuery?.padding.bottom ?? 0;
  final viewInsetsBottom = mediaQuery?.viewInsets.bottom ?? 0;
  final bottomMargin = useCustomKeypad
      ? 236 + safeBottom
      : 16 + safeBottom + viewInsetsBottom;

  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      content: Text(message),
    ),
  );
}
