import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

final class ScaleTrendPoint {
  const ScaleTrendPoint({
    required this.sessionId,
    required this.time,
    required this.score,
    this.scaleName,
  });

  final int sessionId;
  final DateTime time;
  final double score;
  final String? scaleName;
}

class ScaleScoreTrendChartCard extends StatelessWidget {
  const ScaleScoreTrendChartCard({
    super.key,
    required this.points,
    this.title = '作答趋势',
    this.scoreLabel = '总分',
    this.errorMessage,
    this.onRetry,
  });

  final List<ScaleTrendPoint> points;
  final String title;
  final String scoreLabel;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = (errorMessage ?? '').trim().isNotEmpty;

    if (hasError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(errorMessage!, style: theme.textTheme.bodySmall),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(onPressed: onRetry, child: const Text('重试')),
              ],
            ],
          ),
        ),
      );
    }

    if (points.length < 3) {
      return const SizedBox.shrink();
    }

    final dataPoints = points.toList(growable: false);
    final values = dataPoints.map((it) => it.score).toList(growable: false);
    final minYRaw = values.reduce((a, b) => a < b ? a : b);
    final maxYRaw = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxYRaw - minYRaw).abs() < 1
        ? 1.0
        : (maxYRaw - minYRaw) * 0.15;
    final minY = (minYRaw - padding).floorToDouble();
    final maxY = (maxYRaw + padding).ceilToDouble();

    final interval = _bottomLabelInterval(dataPoints.length);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxY - minY) / 4).clamp(1, 9999),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 0.8,
                      ),
                      left: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 0.8,
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: ((maxY - minY) / 4).clamp(1, 9999),
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dataPoints.length) {
                            return const SizedBox.shrink();
                          }
                          final time = dataPoints[index].time.toLocal();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${time.month}/${time.day}',
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (spots) {
                        return spots
                            .map((spot) {
                              final index = spot.x.toInt();
                              if (index < 0 || index >= dataPoints.length) {
                                return null;
                              }
                              final point = dataPoints[index];
                              final local = point.time.toLocal();
                              final hour = local.hour.toString().padLeft(
                                2,
                                '0',
                              );
                              final minute = local.minute.toString().padLeft(
                                2,
                                '0',
                              );
                              final scaleNameText = (point.scaleName ?? '')
                                  .trim();
                              final scaleLine = scaleNameText.isEmpty
                                  ? ''
                                  : '$scaleNameText\n';
                              return LineTooltipItem(
                                '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute\n'
                                '$scaleLine$scoreLabel ${point.score.toStringAsFixed(1)}',
                                theme.textTheme.bodySmall!.copyWith(
                                  color: colorScheme.onInverseSurface,
                                ),
                              );
                            })
                            .toList(growable: false);
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3.2,
                            color: colorScheme.primary,
                            strokeColor: colorScheme.surface,
                            strokeWidth: 1.2,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                      spots: [
                        for (var i = 0; i < dataPoints.length; i++)
                          FlSpot(i.toDouble(), dataPoints[i].score),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _bottomLabelInterval(int length) {
    if (length <= 4) return 1;
    if (length <= 8) return 2;
    return (length / 4).ceilToDouble();
  }
}
