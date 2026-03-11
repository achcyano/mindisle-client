final class SideEffectSummaryItem {
  const SideEffectSummaryItem({
    required this.symptom,
    required this.count,
    required this.averageSeverity,
  });

  final String symptom;
  final int count;
  final double? averageSeverity;
}

final class WeightTrendPoint {
  const WeightTrendPoint({required this.date, required this.weightKg});

  final DateTime? date;
  final double? weightKg;
}
