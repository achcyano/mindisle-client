final class DoctorBindingCode {
  const DoctorBindingCode({
    required this.code,
    required this.expiresAt,
    required this.qrPayload,
  });

  final String code;
  final DateTime? expiresAt;
  final String qrPayload;
}

final class DoctorBindingHistoryItem {
  const DoctorBindingHistoryItem({
    required this.bindingId,
    required this.patientUserId,
    required this.patientName,
    required this.status,
    required this.boundAt,
    required this.unboundAt,
  });

  final int bindingId;
  final int patientUserId;
  final String patientName;
  final String status;
  final DateTime? boundAt;
  final DateTime? unboundAt;
}

final class DoctorBindingHistoryResult {
  const DoctorBindingHistoryResult({
    required this.items,
    required this.nextCursor,
  });

  final List<DoctorBindingHistoryItem> items;
  final String? nextCursor;
}
