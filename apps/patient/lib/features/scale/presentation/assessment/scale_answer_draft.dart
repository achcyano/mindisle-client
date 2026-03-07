final class ScaleAnswerDraft {
  const ScaleAnswerDraft({
    this.optionId,
    this.optionIds = const <int>[],
    this.textValue,
    this.timeValue,
    this.durationMinutes,
    this.isDirty = false,
  });

  const ScaleAnswerDraft.singleChoice({
    required int optionId,
    bool isDirty = false,
  }) : this(optionId: optionId, isDirty: isDirty);

  const ScaleAnswerDraft.multiChoice({
    required List<int> optionIds,
    bool isDirty = false,
  }) : this(optionIds: optionIds, isDirty: isDirty);

  const ScaleAnswerDraft.text({
    required String textValue,
    bool isDirty = false,
  }) : this(textValue: textValue, isDirty: isDirty);

  const ScaleAnswerDraft.time({
    required String timeValue,
    bool isDirty = false,
  }) : this(timeValue: timeValue, isDirty: isDirty);

  const ScaleAnswerDraft.duration({
    required int durationMinutes,
    bool isDirty = false,
  }) : this(durationMinutes: durationMinutes, isDirty: isDirty);

  final int? optionId;
  final List<int> optionIds;
  final String? textValue;
  final String? timeValue;
  final int? durationMinutes;
  final bool isDirty;

  ScaleAnswerDraft copyWith({
    Object? optionId = _sentinel,
    List<int>? optionIds,
    Object? textValue = _sentinel,
    Object? timeValue = _sentinel,
    Object? durationMinutes = _sentinel,
    bool? isDirty,
  }) {
    return ScaleAnswerDraft(
      optionId: identical(optionId, _sentinel) ? this.optionId : optionId as int?,
      optionIds: optionIds ?? this.optionIds,
      textValue: identical(textValue, _sentinel)
          ? this.textValue
          : textValue as String?,
      timeValue: identical(timeValue, _sentinel)
          ? this.timeValue
          : timeValue as String?,
      durationMinutes: identical(durationMinutes, _sentinel)
          ? this.durationMinutes
          : durationMinutes as int?,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

const Object _sentinel = Object();
