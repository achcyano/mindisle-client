import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

final class ScaleRadarDimensionEntry {
  const ScaleRadarDimensionEntry({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class ScaleDimensionRadarChartCard extends StatelessWidget {
  const ScaleDimensionRadarChartCard({
    super.key,
    required this.entries,
  });

  final List<ScaleRadarDimensionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.length < 3) {
      return const SizedBox.shrink();
    }

    final colorScheme = theme.colorScheme;
    final maxValue = _maxValue(entries);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('维度雷达图', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 5,
                  ticksTextStyle: theme.textTheme.labelSmall!,
                  tickBorderData: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.8,
                  ),
                  gridBorderData: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.9),
                    width: 0.8,
                  ),
                  radarBorderData: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.8,
                  ),
                  titlePositionPercentageOffset: 0.18,
                  getTitle: (index, angle) {
                    if (index < 0 || index >= entries.length) {
                      return const RadarChartTitle(text: '');
                    }
                    return RadarChartTitle(text: _shortLabel(entries[index].label));
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: colorScheme.primary.withValues(alpha: 0.2),
                      borderColor: colorScheme.primary,
                      borderWidth: 2,
                      entryRadius: 2.5,
                      dataEntries: [
                        for (final item in entries)
                          RadarEntry(value: item.value.clamp(0, maxValue)),
                      ],
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in entries)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${item.label} ${item.value.toStringAsFixed(1)}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _maxValue(List<ScaleRadarDimensionEntry> values) {
    final maxRaw = values
        .map((it) => it.value)
        .reduce((a, b) => a > b ? a : b);
    final scaled = maxRaw <= 0 ? 1.0 : maxRaw * 1.2;
    return scaled < 1 ? 1.0 : scaled;
  }

  String _shortLabel(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 8) return trimmed;
    return '${trimmed.substring(0, 8)}…';
  }
}
