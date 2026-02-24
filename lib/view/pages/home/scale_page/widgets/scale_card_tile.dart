import 'package:flutter/material.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ScaleCardTile extends StatelessWidget {
  const ScaleCardTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.onTap,
    this.isOpening = false,
    this.lastCompletedAt,
  });

  final String title;
  final String subtitle;
  final String code;
  final VoidCallback onTap;
  final bool isOpening;
  final DateTime? lastCompletedAt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
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
                    const SizedBox(height: 6),
                    Text(
                      _buildLastCompletedLabel(lastCompletedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isOpening)
                SizedBox.square(
                  dimension: 20,
                  child: const FittedBox(child: CircularProgressIndicatorM3E()),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLastCompletedLabel(DateTime? value) {
    if (value == null) {
      return '\u4e0a\u6b21\u5b8c\u6210\uff1a\u6682\u65e0\u8bb0\u5f55';
    }
    final beijingTime = _toBeijingTime(value);
    final month = beijingTime.month.toString().padLeft(2, '0');
    final day = beijingTime.day.toString().padLeft(2, '0');
    final hour = beijingTime.hour.toString().padLeft(2, '0');
    final minute = beijingTime.minute.toString().padLeft(2, '0');
    return '\u4e0a\u6b21\u5b8c\u6210\uff1a'
        '${beijingTime.year}-$month-$day $hour:$minute';
  }

  DateTime _toBeijingTime(DateTime value) {
    final utc = value.isUtc ? value : value.toUtc();
    return utc.add(const Duration(hours: 8));
  }
}
