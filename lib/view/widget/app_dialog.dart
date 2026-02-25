import 'package:flutter/material.dart';

// Padding around title inside AlertDialog content area: left, top, right, bottom.
const EdgeInsets _appDialogTitlePadding = EdgeInsets.fromLTRB(22, 16, 20, 10);
// Padding around body content inside AlertDialog content area: left, top, right, bottom.
const EdgeInsets _appDialogContentPadding = EdgeInsets.fromLTRB(22, 0, 20, 20);
// Outer padding of actions row inside AlertDialog: left, top, right, bottom.
const EdgeInsets _appDialogActionsPadding = EdgeInsets.fromLTRB(10, 0, 10, 8);
// Extra padding applied to each action button.
const EdgeInsets _appDialogButtonPadding = EdgeInsets.symmetric(horizontal: 8);

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double widthFactor = 0.88,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool? requestFocus,
}) {
  final normalizedWidthFactor = widthFactor.clamp(0.3, 1.0).toDouble();

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    requestFocus: requestFocus,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.sizeOf(dialogContext).width;
      final targetWidth = screenWidth * normalizedWidthFactor;
      final theme = Theme.of(dialogContext);
      return DialogTheme(
        data: _fixedWidthDialogTheme(
          base: theme.dialogTheme,
          width: targetWidth,
        ),
        child: Builder(builder: builder),
      );
    },
  );
}

AlertDialog buildAppAlertDialog({
  Widget? icon,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  bool scrollable = false,
  EdgeInsetsGeometry? titlePadding,
  EdgeInsetsGeometry? contentPadding,
  EdgeInsetsGeometry? actionsPadding,
  EdgeInsetsGeometry? buttonPadding,
}) {
  return AlertDialog(
    icon: icon,
    title: title,
    content: content,
    actions: actions,
    scrollable: scrollable,
    titlePadding: titlePadding ?? _appDialogTitlePadding,
    contentPadding: contentPadding ?? _appDialogContentPadding,
    actionsPadding: actionsPadding ?? _appDialogActionsPadding,
    buttonPadding: buttonPadding ?? _appDialogButtonPadding,
  );
}

DialogThemeData _fixedWidthDialogTheme({
  required DialogThemeData base,
  required double width,
}) {
  return DialogThemeData(
    backgroundColor: base.backgroundColor,
    elevation: base.elevation,
    shadowColor: base.shadowColor,
    surfaceTintColor: base.surfaceTintColor,
    shape: base.shape,
    alignment: base.alignment,
    iconColor: base.iconColor,
    titleTextStyle: base.titleTextStyle,
    contentTextStyle: base.contentTextStyle,
    actionsPadding: base.actionsPadding,
    barrierColor: base.barrierColor,
    insetPadding: EdgeInsets.zero,
    clipBehavior: base.clipBehavior,
    constraints: BoxConstraints.tightFor(width: width),
  );
}
