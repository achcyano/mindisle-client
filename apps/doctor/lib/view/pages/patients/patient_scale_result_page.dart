import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/presentation/providers/doctor_scale_providers.dart';
import 'package:doctor/features/doctor_scale/presentation/result/doctor_scale_session_result_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorScaleSessionResultPage extends ConsumerStatefulWidget {
  const DoctorScaleSessionResultPage({super.key, required this.args});

  final DoctorScaleSessionResultArgs args;

  static final route = AppRouteArg<void, DoctorScaleSessionResultArgs>(
    path: '/patients/scale/result',
    builder: (args) => DoctorScaleSessionResultPage(args: args),
  );

  @override
  ConsumerState<DoctorScaleSessionResultPage> createState() =>
      _DoctorScaleSessionResultPageState();
}

class _DoctorScaleSessionResultPageState
    extends ConsumerState<DoctorScaleSessionResultPage> {
  static const int _historyFetchLimit = 50;
  static const int _historyMaxPages = 10;
  static const int _historyMaxScalePoints = 120;

  bool _isLoading = false;
  DoctorScaleSessionResult? _result;
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
        .read(fetchDoctorScaleSessionResultUseCaseProvider)
        .execute(
          patientUserId: widget.args.patientUserId,
          sessionId: widget.args.sessionId,
        );
    if (!_isRequestActive(requestToken)) return;
    switch (result) {
      case Failure<DoctorScaleSessionResult>(error: final error):
        final message = error.code == 40020 ? '结果暂未生成，请稍后重试' : error.message;
        setState(() {
          _isLoading = false;
          _errorMessage = message;
          _result = null;
          _historyErrorMessage = null;
          _trendPoints = const <ScaleTrendPoint>[];
          _radarEntries = const <ScaleRadarDimensionEntry>[];
        });
        return;
      case Success<DoctorScaleSessionResult>(data: final data):
        final radarEntries = _buildRadarEntries(data);
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _result = data;
          _historyErrorMessage = null;
          _trendPoints = const <ScaleTrendPoint>[];
          _radarEntries = radarEntries;
        });
        unawaited(_loadSupplementaryHistory(requestToken, data));
        return;
    }
  }

  Future<void> _loadSupplementaryHistory(
    int requestToken,
    DoctorScaleSessionResult result,
  ) async {
    final historyResult = await _fetchTrendHistoryPages();
    if (!_isRequestActive(requestToken)) return;
    switch (historyResult) {
      case Success<List<DoctorScaleAnswerRecord>>(data: final historyItems):
        setState(() {
          _historyErrorMessage = null;
          _trendPoints = _buildTrendPoints(
            currentSessionId: widget.args.sessionId,
            result: result,
            historyItems: historyItems,
          );
        });
      case Failure<List<DoctorScaleAnswerRecord>>(error: final error):
        setState(() {
          _historyErrorMessage = error.message;
          _trendPoints = const <ScaleTrendPoint>[];
        });
    }
  }

  Future<Result<List<DoctorScaleAnswerRecord>>>
  _fetchTrendHistoryPages() async {
    final mergedByRecordId = <int, DoctorScaleAnswerRecord>{};
    String? cursor;
    var pageCount = 0;
    while (pageCount < _historyMaxPages) {
      var shouldStop = false;
      final result = await ref
          .read(fetchDoctorScaleAnswerRecordsUseCaseProvider)
          .execute(
            patientUserId: widget.args.patientUserId,
            limit: _historyFetchLimit,
            cursor: cursor,
          );
      switch (result) {
        case Failure<DoctorScaleAnswerRecordListResult>(error: final error):
          return Failure(error);
        case Success<DoctorScaleAnswerRecordListResult>(data: final page):
          for (final item in page.items) {
            mergedByRecordId[item.recordId] = item;
          }
          final targetPointCount = mergedByRecordId.values
              .where(_isSameScale)
              .where((item) => item.numericScore != null)
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
    return Success(mergedByRecordId.values.toList(growable: false));
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
    required int currentSessionId,
    required DoctorScaleSessionResult result,
    required List<DoctorScaleAnswerRecord> historyItems,
  }) {
    final points = historyItems
        .where(_isSameScale)
        .where((item) => item.numericScore != null)
        .map((item) {
          final time = item.answeredAt;
          if (time == null) return null;
          return ScaleTrendPoint(
            sessionId: item.sessionId ?? item.recordId,
            time: time,
            score: item.numericScore!,
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

  bool _isSameScale(DoctorScaleAnswerRecord item) {
    if (widget.args.scaleId != null && item.scaleId != null) {
      return item.scaleId == widget.args.scaleId;
    }
    final expectedCode = widget.args.scaleCode?.trim().toUpperCase();
    final actualCode = item.scaleCode?.trim().toUpperCase();
    if (expectedCode != null && expectedCode.isNotEmpty) {
      return actualCode == expectedCode;
    }
    return true;
  }

  List<ScaleRadarDimensionEntry> _buildRadarEntries(
    DoctorScaleSessionResult result,
  ) {
    final scaleCode = _resolveScaleCode();
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

  List<ScaleDimensionResultItemData> _toDimensionItems(
    DoctorScaleSessionResult result,
  ) {
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

  String? _resolveScaleCode() {
    final code = widget.args.scaleCode?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }
    final normalizedName = (widget.args.scaleName ?? '').trim().toUpperCase();
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
