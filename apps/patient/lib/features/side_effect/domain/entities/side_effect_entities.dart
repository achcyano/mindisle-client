final class SideEffectRecord {
  const SideEffectRecord({
    required this.sideEffectId,
    required this.symptom,
    required this.severity,
    required this.note,
    required this.recordedAt,
    required this.createdAt,
  });

  final int sideEffectId;
  final String symptom;
  final int severity;
  final String? note;
  final DateTime? recordedAt;
  final DateTime? createdAt;
}

final class SideEffectListResult {
  const SideEffectListResult({
    required this.items,
    required this.nextCursor,
  });

  final List<SideEffectRecord> items;
  final String? nextCursor;
}

final class CreateSideEffectPayload {
  const CreateSideEffectPayload({
    required this.symptom,
    required this.severity,
    this.note,
    this.recordedAt,
  });

  final String symptom;
  final int severity;
  final String? note;
  final DateTime? recordedAt;
}
