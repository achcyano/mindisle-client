import 'package:flutter/material.dart';

class ScaleCardTile extends StatelessWidget {
  const ScaleCardTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.onTap,
    this.isOpening = false,
  });

  final String title;
  final String subtitle;
  final String code;
  final VoidCallback onTap;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isOpening ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.78),
                ),
                alignment: Alignment.center,
                child: Text(
                  code,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isOpening)
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: colorScheme.primary,
                  ),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
