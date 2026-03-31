import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

final class ScaleRadarDimensionEntry {
  const ScaleRadarDimensionEntry({
    required this.label,
    required this.value,
    this.displayValue,
    this.maxValue,
  });

  final String label;
  final double value;
  final double? displayValue;
  final double? maxValue;
}

class ScaleDimensionRadarChartCard extends StatelessWidget {
  const ScaleDimensionRadarChartCard({
    super.key,
    required this.entries,
    this.title = '维度雷达图',
    this.maxValue,
  });

  final List<ScaleRadarDimensionEntry> entries;
  final String title;
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.length < 3) {
      return const SizedBox.shrink();
    }

    final colorScheme = theme.colorScheme;
    final effectiveMaxValue = _resolveMaxValue(entries);
    final chartDataSets = <RadarDataSet>[
      _axisAnchorDataSet(value: 0, entryCount: entries.length),
      _axisAnchorDataSet(value: effectiveMaxValue, entryCount: entries.length),
      RadarDataSet(
        fillColor: colorScheme.primary.withValues(alpha: 0.2),
        borderColor: colorScheme.primary,
        borderWidth: 2,
        entryRadius: 2.5,
        dataEntries: [
          for (final item in entries)
            RadarEntry(
              value: _toPlotValue(
                item,
                effectiveMaxValue: effectiveMaxValue,
              ).clamp(0, effectiveMaxValue),
            ),
        ],
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
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
                    return RadarChartTitle(
                      text: _shortLabel(entries[index].label),
                    );
                  },
                  dataSets: chartDataSets,
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
                    label: Text(
                      '${item.label} ${(item.displayValue ?? item.value).toStringAsFixed(2)}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _resolveMaxValue(List<ScaleRadarDimensionEntry> values) {
    if (maxValue case final configured?
        when configured.isFinite && configured > 0) {
      return configured;
    }

    final hasPerDimensionMax = values.any(
      (it) => it.maxValue != null && it.maxValue!.isFinite && it.maxValue! > 0,
    );
    if (hasPerDimensionMax) {
      final maxAxis = values
          .map((it) => it.maxValue)
          .whereType<double>()
          .where((it) => it.isFinite && it > 0)
          .fold<double>(0, math.max);
      if (maxAxis > 0) {
        return maxAxis;
      }
    }

    final validValues = values
        .map((entry) => _toPlotValue(entry, effectiveMaxValue: maxValue ?? 0))
        .where((it) => it.isFinite && it >= 0)
        .toList(growable: false);
    if (validValues.isEmpty) {
      return 1;
    }

    final maxRaw = validValues.reduce(math.max);
    const stableBounds = <double>[1, 5, 10, 20, 50, 100, 200, 500, 1000];
    for (final bound in stableBounds) {
      if (maxRaw <= bound) {
        return bound;
      }
    }

    final magnitude = math.pow(10, (math.log(maxRaw) / math.ln10).floor());
    final step = magnitude.toDouble();
    return (maxRaw / step).ceilToDouble() * step;
  }

  double _toPlotValue(
    ScaleRadarDimensionEntry entry, {
    required double effectiveMaxValue,
  }) {
    if (entry.maxValue case final axisMax?
        when axisMax.isFinite && axisMax > 0) {
      return (entry.value / axisMax) * effectiveMaxValue;
    }
    return entry.value;
  }

  String _shortLabel(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 8) return trimmed;
    return '${trimmed.substring(0, 8)}…';
  }

  RadarDataSet _axisAnchorDataSet({
    required double value,
    required int entryCount,
  }) {
    return RadarDataSet(
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      entryRadius: 0,
      dataEntries: List<RadarEntry>.generate(
        entryCount,
        (_) => RadarEntry(value: value),
        growable: false,
      ),
    );
  }
}
