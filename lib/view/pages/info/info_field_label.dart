import 'package:flutter/material.dart';

class InfoFieldLabel extends StatelessWidget {
  const InfoFieldLabel({
    required this.text,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
    super.key,
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.primary,
    );

    return Padding(
      padding: padding,
      child: Text(text, style: style),
    );
  }
}
