enum UserEventType {
  openScale,
  continueScaleSession,
  bindDoctor,
  importMedicationPlan,
  updateBasicProfile,
  unknown,
}

final class UserEventItem {
  const UserEventItem({
    required this.eventName,
    required this.eventType,
    required this.dueAt,
    required this.persistent,
    required this.rawPayload,
    this.scaleId,
    this.scaleCode,
    this.scaleName,
    this.intervalDays,
    this.sessionId,
    this.progress,
    this.activeMedicationCount,
    this.anchor,
  });

  final String eventName;
  final UserEventType eventType;
  final DateTime? dueAt;
  final bool persistent;
  final Map<String, dynamic> rawPayload;

  final int? scaleId;
  final String? scaleCode;
  final String? scaleName;
  final int? intervalDays;
  final int? sessionId;
  final int? progress;
  final int? activeMedicationCount;
  final String? anchor;
}

final class UserEventList {
  const UserEventList({
    required this.generatedAt,
    required this.items,
  });

  final DateTime? generatedAt;
  final List<UserEventItem> items;
}

final class DoctorBindingStatus {
  const DoctorBindingStatus({
    required this.isBound,
    required this.boundAt,
    required this.unboundAt,
    required this.updatedAt,
  });

  final bool isBound;
  final DateTime? boundAt;
  final DateTime? unboundAt;
  final DateTime? updatedAt;
}
