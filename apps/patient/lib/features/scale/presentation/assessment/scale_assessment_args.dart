final class ScaleAssessmentArgs {
  const ScaleAssessmentArgs({required this.scaleId, required this.sessionId});

  final int scaleId;
  final int sessionId;

  @override
  bool operator ==(Object other) {
    return other is ScaleAssessmentArgs &&
        other.scaleId == scaleId &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode => Object.hash(scaleId, sessionId);
}
