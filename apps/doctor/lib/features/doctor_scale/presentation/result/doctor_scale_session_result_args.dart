final class DoctorScaleSessionResultArgs {
  const DoctorScaleSessionResultArgs({
    required this.patientUserId,
    required this.sessionId,
    required this.scaleId,
    this.scaleCode,
    this.scaleName,
  });

  final int patientUserId;
  final int sessionId;
  final int? scaleId;
  final String? scaleCode;
  final String? scaleName;

  @override
  bool operator ==(Object other) {
    return other is DoctorScaleSessionResultArgs &&
        other.patientUserId == patientUserId &&
        other.sessionId == sessionId &&
        other.scaleId == scaleId &&
        other.scaleCode == scaleCode &&
        other.scaleName == scaleName;
  }

  @override
  int get hashCode =>
      Object.hash(patientUserId, sessionId, scaleId, scaleCode, scaleName);
}
