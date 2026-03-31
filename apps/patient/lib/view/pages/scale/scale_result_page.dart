import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_ui/app_ui.dart';
import 'package:patient/core/result/result.dart';
import 'package:patient/features/scale/domain/entities/scale_entities.dart';
import 'package:patient/features/scale/presentation/result/scale_result_args.dart';
import 'package:patient/features/scale/presentation/providers/scale_providers.dart';

class ScaleResultPage extends ConsumerStatefulWidget {
  const ScaleResultPage({super.key, required this.args});

  final ScaleResultArgs args;

  static final route = AppRouteArg<void, ScaleResultArgs>(
    path: '/home/scale/result',
    builder: (args) => ScaleResultPage(args: args),
  );

  @override
  ConsumerState<ScaleResultPage> createState() => _ScaleResultPageState();
}

class _ScaleResultPageState extends ConsumerState<ScaleResultPage> {
  static const int _historyPageLimit = 50;
  static const int _historyMaxPages = 10;
  static const int _historyMaxScalePoints = 120;

  bool _isLoading = false;
  ScaleResult? _result;
  String? _errorMessage;
  String? _historyErrorMessage;
  List<ScaleTrendPoint> _trendPoints = const <ScaleTrendPoint>[];
  List<ScaleRadarDimensionEntry> _radarEntries =
      const <ScaleRadarDimensionEntry>[];
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResult();
    });
  }

  Future<void> _loadResult() async {
    if (_isLoading) return;
    final requestToken = ++_requestToken;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _historyErrorMessage = null;
    });

    final result = await ref
        .read(fetchScaleSessionResultUseCaseProvider)
        .execute(sessionId: widget.args.sessionId);
    if (!_isRequestActive(requestToken)) return;
    switch (result) {
      case Failure<ScaleResult>(error: final error):
        var message = error.message;
        if (error.code == 40020 && error.statusCode == 409) {
          message = '结果暂未生成，请稍后重试';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
          _result = null;
          _historyErrorMessage = null;
          _trendPoints = const <ScaleTrendPoint>[];
          _radarEntries = const <ScaleRadarDimensionEntry>[];
        });
        return;
      case Success<ScaleResult>(data: final data):
        final radarEntries = _buildRadarEntries(
          data,
          dimensionMaxById: const <String, double>{},
          scaleCode: _guessScaleCode(widget.args.scaleName),
        );
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _result = data;
          _historyErrorMessage = null;
          _trendPoints = const <ScaleTrendPoint>[];
          _radarEntries = radarEntries;
        });
        unawaited(_loadSupplementaryDetail(requestToken, data));
        unawaited(_loadSupplementaryHistory(requestToken, data));
        return;
    }
  }

  Future<void> _loadSupplementaryDetail(
    int requestToken,
    ScaleResult result,
  ) async {
    final detailResult = await ref
        .read(fetchScaleDetailUseCaseProvider)
        .execute(scaleRef: widget.args.scaleId.toString());
    if (!_isRequestActive(requestToken)) return;
    switch (detailResult) {
      case Success<ScaleDetail>(data: final detail):
        setState(() {
          _radarEntries = _buildRadarEntries(
            result,
            dimensionMaxById: _buildDimensionMaxById(detail),
            scaleCode: detail.code,
          );
        });
      case Failure<ScaleDetail>():
        return;
    }
  }

  Future<void> _loadSupplementaryHistory(
    int requestToken,
    ScaleResult result,
  ) async {
    final historyResult = await _fetchTrendHistoryPages(
      scaleId: widget.args.scaleId,
    );
    if (!_isRequestActive(requestToken)) return;
    switch (historyResult) {
      case Success<List<ScaleHistoryItem>>(data: final historyItems):
        setState(() {
          _historyErrorMessage = null;
          _trendPoints = _buildTrendPoints(
            scaleId: widget.args.scaleId,
            currentSessionId: widget.args.sessionId,
            result: result,
            historyItems: historyItems,
          );
        });
      case Failure<List<ScaleHistoryItem>>(error: final error):
        setState(() {
          _historyErrorMessage = error.message;
          _trendPoints = const <ScaleTrendPoint>[];
        });
    }
  }

  Future<Result<List<ScaleHistoryItem>>> _fetchTrendHistoryPages({
    required int scaleId,
  }) async {
    final mergedBySessionId = <int, ScaleHistoryItem>{};
    String? cursor;
    var pageCount = 0;
    while (pageCount < _historyMaxPages) {
      var shouldStop = false;
      final result = await ref
          .read(fetchScaleHistoryUseCaseProvider)
          .execute(limit: _historyPageLimit, cursor: cursor);
      switch (result) {
        case Failure<ScaleHistoryPage>(error: final error):
          return Failure(error);
        case Success<ScaleHistoryPage>(data: final page):
          for (final item in page.items) {
            mergedBySessionId[item.sessionId] = item;
          }
          final targetPointCount = mergedBySessionId.values
              .where(
                (item) => item.scaleId == scaleId && item.totalScore != null,
              )
              .length;
          final nextCursor = page.nextCursor;
          final hasNext = nextCursor != null && nextCursor.isNotEmpty;
          if (targetPointCount >= _historyMaxScalePoints ||
              !hasNext ||
              page.items.isEmpty) {
            shouldStop = true;
          } else {
            cursor = nextCursor;
          }
      }
      if (shouldStop) break;
      pageCount += 1;
    }
    return Success(mergedBySessionId.values.toList(growable: false));
  }

  bool _isRequestActive(int requestToken) {
    return mounted && requestToken == _requestToken;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showTrendChart =
        _historyErrorMessage != null || _trendPoints.length >= 3;
    final showRadarChart = _radarEntries.length >= 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.args.scaleName?.trim().isNotEmpty == true
              ? '${widget.args.scaleName} 结果'
              : '量表结果',
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loadResult,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading && _result == null
            ? const Center(child: CircularProgressIndicatorM3E())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadResult,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            : _result == null
            ? Center(
                child: FilledButton(
                  onPressed: _loadResult,
                  child: const Text('加载结果'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                children: [
                  ScaleResultSummaryCard(
                    data: ScaleResultSummaryData(
                      title: _result!.bandLevelName,
                      totalScore: _result!.totalScore,
                      resultText: _result!.resultText,
                    ),
                  ),
                  if (_result!.resultFlags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _result!.resultFlags
                              .map(
                                (flag) => Chip(
                                  side: BorderSide(
                                    width: 0.5,
                                    color: colorScheme.error.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  label: Text(flag),
                                  backgroundColor: colorScheme.errorContainer
                                      .withValues(alpha: 0.55),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (showTrendChart) ...[
                    ScaleScoreTrendChartCard(
                      points: _trendPoints,
                      errorMessage: _historyErrorMessage,
                      onRetry: _loadResult,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showRadarChart) ...[
                    ScaleDimensionRadarChartCard(entries: _radarEntries),
                    const SizedBox(height: 8),
                  ],
                  ScaleDimensionResultList(
                    dimensionResults: _toDimensionItems(_result!),
                    dimensionScores: _result!.dimensionScores,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('返回'),
                  ),
                ],
              ),
      ),
    );
  }

  List<ScaleTrendPoint> _buildTrendPoints({
    required int scaleId,
    required int currentSessionId,
    required ScaleResult result,
    required List<ScaleHistoryItem> historyItems,
  }) {
    final points = historyItems
        .where((item) => item.scaleId == scaleId)
        .where((item) => item.totalScore != null)
        .map((item) {
          final time = item.submittedAt ?? item.updatedAt;
          if (time == null) return null;
          return ScaleTrendPoint(
            sessionId: item.sessionId,
            time: time,
            score: item.totalScore!,
          );
        })
        .whereType<ScaleTrendPoint>()
        .toList(growable: true);

    final hasCurrent = points.any((it) => it.sessionId == currentSessionId);
    if (!hasCurrent && result.totalScore != null) {
      points.add(
        ScaleTrendPoint(
          sessionId: currentSessionId,
          time: result.computedAt ?? DateTime.now().toUtc(),
          score: result.totalScore!,
        ),
      );
    }

    points.sort((a, b) {
      final compareTime = a.time.compareTo(b.time);
      if (compareTime != 0) return compareTime;
      return a.sessionId.compareTo(b.sessionId);
    });
    return points;
  }

  List<ScaleRadarDimensionEntry> _buildRadarEntries(
    ScaleResult result, {
    required Map<String, double> dimensionMaxById,
    required String? scaleCode,
  }) {
    final dimensionResults = result.dimensionResults;
    if (dimensionResults.isNotEmpty) {
      return dimensionResults
          .map((item) {
            final normalized = normalizeScaleRadarMetric(
              ScaleRadarMetricInput(
                scaleCode: scaleCode,
                dimensionKey: item.dimensionKey,
                dimensionName: item.dimensionName,
                rawScore: item.rawScore,
                averageScore: item.averageScore,
                standardScore: item.standardScore,
                scoreRangeMax: _resolveDimensionMax(
                  dimensionMaxById: dimensionMaxById,
                  dimensionKey: item.dimensionKey,
                  dimensionName: item.dimensionName,
                ),
              ),
            );
            if (normalized == null) return null;
            final label = item.dimensionName.trim().isNotEmpty
                ? item.dimensionName.trim()
                : item.dimensionKey;
            return ScaleRadarDimensionEntry(
              label: label,
              value: normalized.plotValue,
              displayValue: normalized.displayValue,
              maxValue: normalized.axisMax,
            );
          })
          .whereType<ScaleRadarDimensionEntry>()
          .toList(growable: false);
    }

    if (result.dimensionScores.isEmpty) {
      return const <ScaleRadarDimensionEntry>[];
    }

    return result.dimensionScores.entries
        .where((entry) => entry.value.isFinite)
        .map((entry) {
          final normalized = normalizeScaleRadarMetric(
            ScaleRadarMetricInput(
              scaleCode: scaleCode,
              dimensionKey: entry.key,
              dimensionName: entry.key,
              rawScore: entry.value,
              scoreRangeMax: _resolveDimensionMax(
                dimensionMaxById: dimensionMaxById,
                dimensionKey: entry.key,
                dimensionName: entry.key,
              ),
            ),
          );
          if (normalized == null) return null;
          return ScaleRadarDimensionEntry(
            label: entry.key,
            value: normalized.plotValue,
            displayValue: normalized.displayValue,
            maxValue: normalized.axisMax,
          );
        })
        .whereType<ScaleRadarDimensionEntry>()
        .toList(growable: false);
  }

  Map<String, double> _buildDimensionMaxById(ScaleDetail detail) {
    final map = <String, double>{};
    for (final dimension in detail.dimensions) {
      final max = dimension.scoreRange?.max;
      if (max == null || !max.isFinite || max <= 0) {
        continue;
      }

      final keyId = _normalizeDimensionId(dimension.key);
      if (keyId.isNotEmpty) {
        map[keyId] = max;
      }
      final nameId = _normalizeDimensionId(dimension.name);
      if (nameId.isNotEmpty) {
        map[nameId] = max;
      }
    }
    return map;
  }

  double? _resolveDimensionMax({
    required Map<String, double> dimensionMaxById,
    required String dimensionKey,
    required String dimensionName,
  }) {
    final keyId = _normalizeDimensionId(dimensionKey);
    if (keyId.isNotEmpty) {
      final maxByKey = dimensionMaxById[keyId];
      if (maxByKey != null) {
        return maxByKey;
      }
    }
    final nameId = _normalizeDimensionId(dimensionName);
    if (nameId.isNotEmpty) {
      final maxByName = dimensionMaxById[nameId];
      if (maxByName != null) {
        return maxByName;
      }
    }
    return null;
  }

  List<ScaleDimensionResultItemData> _toDimensionItems(ScaleResult result) {
    return result.dimensionResults
        .map(
          (item) => ScaleDimensionResultItemData(
            dimensionKey: item.dimensionKey,
            dimensionName: item.dimensionName,
            rawScore: item.rawScore,
            averageScore: item.averageScore,
            standardScore: item.standardScore,
            levelName: item.levelName,
          ),
        )
        .toList(growable: false);
  }

  String _normalizeDimensionId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  String? _guessScaleCode(String? scaleName) {
    final normalizedName = (scaleName ?? '').trim().toUpperCase();
    if (normalizedName.isEmpty) return null;
    if (normalizedName.contains('SCL-90') || normalizedName.contains('SCL90')) {
      return 'SCL90';
    }
    if (normalizedName.contains('PHQ-9') || normalizedName.contains('PHQ9')) {
      return 'PHQ9';
    }
    if (normalizedName.contains('GAD-7') || normalizedName.contains('GAD7')) {
      return 'GAD7';
    }
    if (normalizedName.contains('PSQI')) {
      return 'PSQI';
    }
    if (normalizedName.contains('EPQ')) {
      return 'EPQ';
    }
    return null;
  }
}
