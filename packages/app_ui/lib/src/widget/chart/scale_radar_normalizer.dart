import 'dart:math' as math;

final class ScaleRadarMetricInput {
  const ScaleRadarMetricInput({
    required this.scaleCode,
    required this.dimensionKey,
    required this.dimensionName,
    this.rawScore,
    this.averageScore,
    this.standardScore,
    this.scoreRangeMax,
  });

  final String? scaleCode;
  final String dimensionKey;
  final String dimensionName;
  final double? rawScore;
  final double? averageScore;
  final double? standardScore;
  final double? scoreRangeMax;
}

final class ScaleRadarMetricNormalized {
  const ScaleRadarMetricNormalized({
    required this.displayValue,
    required this.plotValue,
    required this.axisMax,
  });

  final double displayValue;
  final double plotValue;
  final double axisMax;
}

ScaleRadarMetricNormalized? normalizeScaleRadarMetric(
  ScaleRadarMetricInput input,
) {
  final normalizedCode = _normalizeScaleCode(input.scaleCode);
  return switch (normalizedCode) {
    'SCL90' => _normalizeScl90Metric(input),
    'PSQI' => _normalizeFixedBoundMetric(input, fixedMax: 3),
    'EPQ' => _normalizeEpqMetric(input),
    'PHQ9' => _normalizeFixedBoundMetric(input, fixedMax: 27),
    'GAD7' => _normalizeFixedBoundMetric(input, fixedMax: 21),
    _ => _normalizeFallbackMetric(input),
  };
}

ScaleRadarMetricNormalized? _normalizeScl90Metric(ScaleRadarMetricInput input) {
  final average = _validScore(input.averageScore);
  double? display = average;
  if (display == null) {
    final raw = _validScore(input.rawScore);
    if (raw != null) {
      final itemCount = _resolveScl90FactorItemCount(
        input.dimensionKey,
        input.dimensionName,
      );
      if (itemCount != null && raw > 5) {
        display = raw / itemCount;
      } else {
        display = raw;
      }
    }
  }
  if (display == null) return null;

  final axis = _mergeAxisMax(
    fixedMax: 5,
    scoreRangeMax: input.scoreRangeMax,
    value: display,
  );
  return ScaleRadarMetricNormalized(
    displayValue: display,
    plotValue: display.clamp(0, axis),
    axisMax: axis,
  );
}

ScaleRadarMetricNormalized? _normalizeEpqMetric(ScaleRadarMetricInput input) {
  final standardScore = _validScore(input.standardScore);
  if (standardScore != null) {
    final axis = _mergeAxisMax(
      fixedMax: 100,
      scoreRangeMax: input.scoreRangeMax,
      value: standardScore,
    );
    return ScaleRadarMetricNormalized(
      displayValue: standardScore,
      plotValue: standardScore.clamp(0, axis),
      axisMax: axis,
    );
  }

  final raw = _firstValidScore([input.rawScore, input.averageScore]);
  if (raw == null) return null;
  final fixedRawMax = _resolveEpqRawMax(
    input.dimensionKey,
    input.dimensionName,
  );
  final axis = _mergeAxisMax(
    fixedMax: fixedRawMax,
    scoreRangeMax: input.scoreRangeMax,
    value: raw,
  );
  return ScaleRadarMetricNormalized(
    displayValue: raw,
    plotValue: raw.clamp(0, axis),
    axisMax: axis,
  );
}

ScaleRadarMetricNormalized? _normalizeFixedBoundMetric(
  ScaleRadarMetricInput input, {
  required double fixedMax,
}) {
  final display = _firstValidScore([
    input.averageScore,
    input.standardScore,
    input.rawScore,
  ]);
  if (display == null) return null;
  final axis = _mergeAxisMax(
    fixedMax: fixedMax,
    scoreRangeMax: input.scoreRangeMax,
    value: display,
  );
  return ScaleRadarMetricNormalized(
    displayValue: display,
    plotValue: display.clamp(0, axis),
    axisMax: axis,
  );
}

ScaleRadarMetricNormalized? _normalizeFallbackMetric(
  ScaleRadarMetricInput input,
) {
  final display = _firstValidScore([
    input.standardScore,
    input.averageScore,
    input.rawScore,
  ]);
  if (display == null) return null;
  final axis = _mergeAxisMax(
    fixedMax: null,
    scoreRangeMax: input.scoreRangeMax,
    value: display,
  );
  return ScaleRadarMetricNormalized(
    displayValue: display,
    plotValue: display.clamp(0, axis),
    axisMax: axis,
  );
}

double? _firstValidScore(List<double?> candidates) {
  for (final value in candidates) {
    final valid = _validScore(value);
    if (valid != null) return valid;
  }
  return null;
}

double? _validScore(double? value) {
  if (value == null || !value.isFinite) return null;
  return value;
}

double _mergeAxisMax({
  required double? fixedMax,
  required double? scoreRangeMax,
  required double value,
}) {
  var axis = _stableAxisMax(value);
  final normalizedFixed = _validAxisMax(fixedMax);
  if (normalizedFixed != null && normalizedFixed > axis) {
    axis = normalizedFixed;
  }
  final normalizedRange = _validAxisMax(scoreRangeMax);
  if (normalizedRange != null && normalizedRange > axis) {
    axis = normalizedRange;
  }
  return axis;
}

double? _validAxisMax(double? value) {
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}

double _stableAxisMax(double value) {
  final positiveValue = value.isFinite ? math.max(value, 1) : 1;
  const stableBounds = <double>[1, 3, 5, 10, 20, 27, 50, 100, 200, 500, 1000];
  for (final bound in stableBounds) {
    if (positiveValue <= bound) {
      return bound;
    }
  }

  final magnitude = math.pow(10, (math.log(positiveValue) / math.ln10).floor());
  final step = magnitude.toDouble();
  return (positiveValue / step).ceilToDouble() * step;
}

double? _resolveEpqRawMax(String dimensionKey, String dimensionName) {
  final key = _normalizeDimensionToken(dimensionKey);
  final name = _normalizeDimensionToken(dimensionName);
  if (key == 'e' || name.contains('外向')) return 21;
  if (key == 'n' || name.contains('神经')) return 24;
  if (key == 'p' || name.contains('精神质')) return 20;
  if (key == 'l' || name.contains('掩饰') || name.contains('说谎')) return 23;
  return null;
}

double? _resolveScl90FactorItemCount(
  String dimensionKey,
  String dimensionName,
) {
  final key = _normalizeDimensionToken(dimensionKey);
  final name = _normalizeDimensionToken(dimensionName);
  const keyMap = <String, double>{
    'somatization': 12,
    'obsessivecompulsive': 10,
    'interpersonalsensitivity': 9,
    'depression': 13,
    'anxiety': 10,
    'hostility': 6,
    'phobicanxiety': 7,
    'paranoidideation': 6,
    'psychoticism': 10,
    'additional': 7,
  };

  final hitByKey = keyMap[key];
  if (hitByKey != null) return hitByKey;

  if (name.contains('躯体')) return 12;
  if (name.contains('强迫')) return 10;
  if (name.contains('人际')) return 9;
  if (name == '抑郁' || name.contains('抑郁')) return 13;
  if (name == '焦虑' || name.contains('焦虑')) return 10;
  if (name.contains('敌对') || name.contains('敌意')) return 6;
  if (name.contains('恐怖')) return 7;
  if (name.contains('偏执')) return 6;
  if (name.contains('精神病')) return 10;
  if (name.contains('其他') || name.contains('附加')) return 7;

  return null;
}

String _normalizeScaleCode(String? value) {
  final normalized = (value ?? '').trim().toUpperCase().replaceAll('-', '');
  if (normalized == 'PHQ9') return 'PHQ9';
  if (normalized == 'GAD7') return 'GAD7';
  if (normalized == 'SCL90') return 'SCL90';
  if (normalized == 'PSQI') return 'PSQI';
  if (normalized == 'EPQ') return 'EPQ';
  return normalized;
}

String _normalizeDimensionToken(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
}
