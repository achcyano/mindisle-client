import 'package:flutter/material.dart';

class ScaleProgressHeader extends StatelessWidget {
  const ScaleProgressHeader({
    super.key,
    required this.currentIndex,
    required this.total,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeTotal = total <= 0 ? 1 : total;
    final safeIndex = currentIndex < 0
        ? 0
        : (currentIndex >= safeTotal ? safeTotal - 1 : currentIndex);
    final progress = (safeIndex + 1) / safeTotal;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '第 ${safeIndex + 1} 题 / 共 $safeTotal 题',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }
}
