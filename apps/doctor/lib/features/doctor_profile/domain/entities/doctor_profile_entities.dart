final class DoctorProfile {
  const DoctorProfile({
    required this.doctorId,
    required this.phone,
    required this.fullName,
    this.title,
    this.hospital,
  });

  final int doctorId;
  final String phone;
  final String fullName;
  final String? title;
  final String? hospital;
}

final class DoctorThresholds {
  const DoctorThresholds({
    this.scl90Threshold,
    this.phq9Threshold,
    this.gad7Threshold,
    this.psqiThreshold,
  });

  final int? scl90Threshold;
  final int? phq9Threshold;
  final int? gad7Threshold;
  final int? psqiThreshold;

  Map<String, dynamic> toJson() {
    return {
      if (scl90Threshold != null) 'scl90Threshold': scl90Threshold,
      if (phq9Threshold != null) 'phq9Threshold': phq9Threshold,
      if (gad7Threshold != null) 'gad7Threshold': gad7Threshold,
      if (psqiThreshold != null) 'psqiThreshold': psqiThreshold,
    };
  }
}
