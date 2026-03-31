const Object _doctorPatientQueryNoChange = Object();
const Object _doctorPatientNoChange = Object();

final class DoctorPatient {
  const DoctorPatient({
    required this.patientUserId,
    required this.fullName,
    required this.phone,
    required this.isAbnormal,
    this.severityGroup,
    this.gender,
    this.birthDate,
    this.age,
    this.latestScl90Score,
    this.latestAssessmentAt,
    this.diagnosis,
  });

  final int patientUserId;
  final String fullName;
  final String phone;
  final bool isAbnormal;
  final String? severityGroup;
  final DoctorPatientGender? gender;
  final DateTime? birthDate;
  final int? age;
  final double? latestScl90Score;
  final DateTime? latestAssessmentAt;
  final String? diagnosis;

  DoctorPatient copyWith({
    Object? severityGroup = _doctorPatientNoChange,
    DoctorPatientGender? gender,
    DateTime? birthDate,
    int? age,
    double? latestScl90Score,
    DateTime? latestAssessmentAt,
    Object? diagnosis = _doctorPatientNoChange,
  }) {
    return DoctorPatient(
      patientUserId: patientUserId,
      fullName: fullName,
      phone: phone,
      isAbnormal: isAbnormal,
      severityGroup: identical(severityGroup, _doctorPatientNoChange)
          ? this.severityGroup
          : severityGroup as String?,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      latestScl90Score: latestScl90Score ?? this.latestScl90Score,
      latestAssessmentAt: latestAssessmentAt ?? this.latestAssessmentAt,
      diagnosis: identical(diagnosis, _doctorPatientNoChange)
          ? this.diagnosis
          : diagnosis as String?,
    );
  }
}

enum DoctorPatientGender {
  unknown('UNKNOWN', '未知'),
  male('MALE', '男'),
  female('FEMALE', '女'),
  other('OTHER', '其他');

  const DoctorPatientGender(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DoctorPatientGender? fromApiValue(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toUpperCase();
    for (final candidate in DoctorPatientGender.values) {
      if (candidate.apiValue == normalized) return candidate;
    }
    return null;
  }
}

typedef DoctorPatientGenderFilter = DoctorPatientGender;

enum DoctorPatientSortBy {
  latestAssessmentAt('latestAssessmentAt', '最近评估时间'),
  scl90Score('scl90Score', 'SCL-90 分数');

  const DoctorPatientSortBy(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum DoctorSortOrder {
  asc('asc', '升序'),
  desc('desc', '降序');

  const DoctorSortOrder(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

final class DoctorPatientQuery {
  const DoctorPatientQuery({
    this.keyword,
    this.gender,
    this.severityGroup,
    this.diagnosisKeyword,
    this.abnormalOnly,
    this.scl90ScoreMin,
    this.scl90ScoreMax,
    this.sortBy = DoctorPatientSortBy.latestAssessmentAt,
    this.sortOrder = DoctorSortOrder.desc,
  });

  final String? keyword;
  final DoctorPatientGenderFilter? gender;
  final String? severityGroup;
  final String? diagnosisKeyword;
  final bool? abnormalOnly;
  final double? scl90ScoreMin;
  final double? scl90ScoreMax;
  final DoctorPatientSortBy sortBy;
  final DoctorSortOrder sortOrder;

  DoctorPatientQuery copyWith({
    Object? keyword = _doctorPatientQueryNoChange,
    Object? gender = _doctorPatientQueryNoChange,
    Object? severityGroup = _doctorPatientQueryNoChange,
    Object? diagnosisKeyword = _doctorPatientQueryNoChange,
    Object? abnormalOnly = _doctorPatientQueryNoChange,
    Object? scl90ScoreMin = _doctorPatientQueryNoChange,
    Object? scl90ScoreMax = _doctorPatientQueryNoChange,
    DoctorPatientSortBy? sortBy,
    DoctorSortOrder? sortOrder,
  }) {
    return DoctorPatientQuery(
      keyword: identical(keyword, _doctorPatientQueryNoChange)
          ? this.keyword
          : keyword as String?,
      gender: identical(gender, _doctorPatientQueryNoChange)
          ? this.gender
          : gender as DoctorPatientGenderFilter?,
      severityGroup: identical(severityGroup, _doctorPatientQueryNoChange)
          ? this.severityGroup
          : severityGroup as String?,
      diagnosisKeyword: identical(diagnosisKeyword, _doctorPatientQueryNoChange)
          ? this.diagnosisKeyword
          : diagnosisKeyword as String?,
      abnormalOnly: identical(abnormalOnly, _doctorPatientQueryNoChange)
          ? this.abnormalOnly
          : abnormalOnly as bool?,
      scl90ScoreMin: identical(scl90ScoreMin, _doctorPatientQueryNoChange)
          ? this.scl90ScoreMin
          : scl90ScoreMin as double?,
      scl90ScoreMax: identical(scl90ScoreMax, _doctorPatientQueryNoChange)
          ? this.scl90ScoreMax
          : scl90ScoreMax as double?,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  int get activeFilterCount {
    var count = 0;
    if (gender != null) count += 1;
    if (severityGroup != null && severityGroup!.trim().isNotEmpty) count += 1;
    if (diagnosisKeyword != null && diagnosisKeyword!.trim().isNotEmpty) {
      count += 1;
    }
    if (abnormalOnly != null) count += 1;
    if (scl90ScoreMin != null || scl90ScoreMax != null) count += 1;
    return count;
  }

  bool isRemoteEqualTo(DoctorPatientQuery other) {
    return keyword?.trim() == other.keyword?.trim() &&
        gender == other.gender &&
        severityGroup?.trim() == other.severityGroup?.trim() &&
        abnormalOnly == other.abnormalOnly &&
        scl90ScoreMin == other.scl90ScoreMin &&
        scl90ScoreMax == other.scl90ScoreMax &&
        sortBy == other.sortBy &&
        sortOrder == other.sortOrder;
  }

  Map<String, dynamic> toQueryParameters({required int limit, String? cursor}) {
    final normalizedKeyword = keyword?.trim();
    final normalizedSeverityGroup = severityGroup?.trim();
    return <String, dynamic>{
      'limit': limit,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      if (normalizedKeyword != null && normalizedKeyword.isNotEmpty)
        'keyword': normalizedKeyword,
      if (gender != null) 'gender': gender!.apiValue,
      if (normalizedSeverityGroup != null && normalizedSeverityGroup.isNotEmpty)
        'severityGroup': normalizedSeverityGroup,
      if (abnormalOnly != null) 'abnormalOnly': abnormalOnly,
      if (scl90ScoreMin != null) 'scl90ScoreMin': scl90ScoreMin,
      if (scl90ScoreMax != null) 'scl90ScoreMax': scl90ScoreMax,
      'sortBy': sortBy.apiValue,
      'sortOrder': sortOrder.apiValue,
    };
  }
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
  const DoctorPatientGrouping({required this.severityGroup});

  final String? severityGroup;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'severityGroup': severityGroup};
  }
}

final class DoctorPatientGroupOption {
  const DoctorPatientGroupOption({
    required this.severityGroup,
    required this.patientCount,
  });

  final String severityGroup;
  final int patientCount;
}

final class DoctorPatientDiagnosisUpdatePayload {
  const DoctorPatientDiagnosisUpdatePayload({required this.diagnosis});

  final String? diagnosis;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'diagnosis': diagnosis};
  }
}

final class DoctorPatientDiagnosisUpdateResult {
  const DoctorPatientDiagnosisUpdateResult({
    required this.patientUserId,
    required this.diagnosis,
    required this.updatedAt,
  });

  final int patientUserId;
  final String? diagnosis;
  final DateTime? updatedAt;
}

final class DoctorPatientGroupingHistoryItem {
  const DoctorPatientGroupingHistoryItem({
    required this.historyId,
    required this.severityGroup,
    required this.changedAt,
    this.operatorDoctorId,
    this.operatorDoctorName,
  });

  final int historyId;
  final String? severityGroup;
  final DateTime? changedAt;
  final int? operatorDoctorId;
  final String? operatorDoctorName;
}

final class DoctorPatientProfile {
  const DoctorPatientProfile({
    required this.patientUserId,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.waistCm,
    required this.usesTcm,
    required this.diseaseHistory,
  });

  final int? patientUserId;
  final String? phone;
  final String? fullName;
  final DoctorPatientGender? gender;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? waistCm;
  final bool? usesTcm;
  final List<String> diseaseHistory;
}

final class DoctorPatientExportFile {
  const DoctorPatientExportFile({
    required this.bytes,
    required this.fileName,
    this.mimeType = 'application/zip',
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
}
