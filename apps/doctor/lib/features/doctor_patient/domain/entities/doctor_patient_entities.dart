final class DoctorPatient {
  const DoctorPatient({
    required this.patientUserId,
    required this.fullName,
    required this.phone,
    required this.isAbnormal,
    this.severityGroup,
    this.treatmentPhase,
  });

  final int patientUserId;
  final String fullName;
  final String phone;
  final bool isAbnormal;
  final String? severityGroup;
  final String? treatmentPhase;
}

final class DoctorPatientListResult {
  const DoctorPatientListResult({
    required this.items,
    required this.nextCursor,
  });

  final List<DoctorPatient> items;
  final String? nextCursor;
}

final class DoctorPatientGrouping {
  const DoctorPatientGrouping({this.severityGroup, this.treatmentPhase});

  final String? severityGroup;
  final String? treatmentPhase;

  Map<String, dynamic> toJson() {
    return {
      if (severityGroup != null) 'severityGroup': severityGroup,
      if (treatmentPhase != null) 'treatmentPhase': treatmentPhase,
    };
  }
}

final class DoctorPatientGroupingHistoryItem {
  const DoctorPatientGroupingHistoryItem({
    required this.historyId,
    required this.severityGroup,
    required this.treatmentPhase,
    required this.createdAt,
  });

  final int historyId;
  final String? severityGroup;
  final String? treatmentPhase;
  final DateTime? createdAt;
}
