import 'package:flutter/material.dart';

class UnsupportedInput extends StatelessWidget {
  const UnsupportedInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '当前题型暂不支持作答，请联系管理员。',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }
}
