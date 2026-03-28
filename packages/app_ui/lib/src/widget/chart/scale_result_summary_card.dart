import 'package:flutter/material.dart';

final class ScaleResultSummaryData {
  const ScaleResultSummaryData({this.title, this.totalScore, this.resultText});

  final String? title;
  final double? totalScore;
  final String? resultText;
}

class ScaleResultSummaryCard extends StatelessWidget {
  const ScaleResultSummaryCard({
    super.key,
    required this.data,
    this.fallbackTitle = '评估完成',
    this.totalScoreLabel = '总分',
    this.fallbackResultText = '请结合医生建议综合判断。',
  });

  final ScaleResultSummaryData data;
  final String fallbackTitle;
  final String totalScoreLabel;
  final String fallbackResultText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleText = (data.title ?? '').trim().isNotEmpty
        ? data.title!.trim()
        : fallbackTitle;
    final scoreText = data.totalScore == null
        ? '--'
        : data.totalScore!.toStringAsFixed(1);
    final resultText = (data.resultText ?? '').trim().isNotEmpty
        ? data.resultText!.trim()
        : fallbackResultText;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titleText, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '$totalScoreLabel：$scoreText',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text(resultText, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
