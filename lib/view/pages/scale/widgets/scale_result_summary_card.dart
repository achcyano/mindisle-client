import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';

class ScaleResultSummaryCard extends StatelessWidget {
  const ScaleResultSummaryCard({super.key, required this.result});

  final ScaleResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = result.bandLevelName ?? '评估完成';
    final scoreText = result.totalScore == null
        ? '--'
        : result.totalScore!.toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '总分：$scoreText',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              result.resultText?.trim().isNotEmpty == true
                  ? result.resultText!
                  : '请结合医生建议综合判断。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
