final class ScaleResultArgs {
  const ScaleResultArgs({
    required this.sessionId,
    required this.scaleId,
    this.scaleName,
  });

  final int sessionId;
  final int scaleId;
  final String? scaleName;

  @override
  bool operator ==(Object other) {
    return other is ScaleResultArgs &&
        other.sessionId == sessionId &&
        other.scaleId == scaleId &&
        other.scaleName == scaleName;
  }

  @override
  int get hashCode => Object.hash(sessionId, scaleId, scaleName);
}
