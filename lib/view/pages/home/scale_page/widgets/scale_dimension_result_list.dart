import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';

class ScaleDimensionResultList extends StatelessWidget {
  const ScaleDimensionResultList({super.key, required this.result});

  final ScaleResult result;

  @override
  Widget build(BuildContext context) {
    final dimensionResults = result.dimensionResults;
    final dimensionScores = result.dimensionScores;
    final colorScheme = Theme.of(context).colorScheme;

    if (dimensionResults.isEmpty && dimensionScores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('维度结果', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (dimensionResults.isNotEmpty)
              for (final item in dimensionResults) ...[
                _DimensionRow(
                  title: item.dimensionName.trim().isNotEmpty
                      ? item.dimensionName
                      : item.dimensionKey,
                  value: _resolveDimensionValue(item),
                  subtitle: item.levelName,
                ),
                const SizedBox(height: 8),
              ]
            else
              for (final entry in dimensionScores.entries) ...[
                _DimensionRow(
                  title: entry.key,
                  value: entry.value.toStringAsFixed(1),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }

  String _resolveDimensionValue(ScaleDimensionResult item) {
    if (item.rawScore != null) return item.rawScore!.toStringAsFixed(1);
    if (item.averageScore != null) return item.averageScore!.toStringAsFixed(2);
    if (item.standardScore != null) {
      return item.standardScore!.toStringAsFixed(1);
    }
    return '--';
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              if ((subtitle ?? '').trim().isNotEmpty)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
        ),
      ],
    );
  }
}
