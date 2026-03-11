import 'package:flutter/material.dart';

class ProfileHeroSection extends StatelessWidget {
  const ProfileHeroSection({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final Widget avatar;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final trimmedSubtitle = subtitle?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Center(child: avatar),
        const SizedBox(height: 3),
        Text(title, style: textTheme.headlineSmall, textAlign: TextAlign.center),
        if (trimmedSubtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            trimmedSubtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                Expanded(child: actions[i]),
                if (i != actions.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
