import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/info/info_page_utils.dart';

typedef _StateRule = String? Function(ProfileState state);

final List<_StateRule> _infoValidationRules = <_StateRule>[
  _validateFullName,
  _validateGender,
  _validateBirthDate,
  (state) => _validateRequiredNumberInRange(
        state.heightCm,
        fieldName: '身高',
        min: 50,
        max: 260,
      ),
  (state) => _validateRequiredNumberInRange(
        state.weightKg,
        fieldName: '体重',
        min: 10,
        max: 500,
      ),
  (state) => _validateRequiredNumberInRange(
        state.waistCm,
        fieldName: '腰围',
        min: 30,
        max: 220,
      ),
];

String? validateInfoBeforeExit(ProfileState state) {
  return _firstStateError(state, _infoValidationRules);
}

String? validateDiseaseHistoryEntry(String entry) {
  if (entry.length > 200) return '疾病名称不能超过 200 个字符';
  if (containsControlChars(entry)) return '疾病名称包含非法字符';
  return null;
}

bool containsControlChars(String value) {
  return RegExp(r'[\x00-\x1F\x7F]').hasMatch(value);
}

String? _firstStateError(ProfileState state, Iterable<_StateRule> rules) {
  for (final rule in rules) {
    final error = rule(state);
    if (error != null) return error;
  }
  return null;
}

String? _validateFullName(ProfileState state) {
  final fullName = state.fullName.trim();
  if (fullName.isEmpty) return '请填写姓名';
  if (fullName.length > 200) return '姓名不能超过 200 个字符';
  if (containsControlChars(fullName)) return '姓名包含非法字符';
  return null;
}

String? _validateGender(ProfileState state) {
  if (state.gender == UserGender.unknown) return '请选择性别';
  return null;
}

String? _validateBirthDate(ProfileState state) {
  final birthText = InfoPageUtils.effectiveBirthDateText(state);
  if (birthText.isEmpty) return '请选择出生日期';

  final birthDate = InfoPageUtils.tryParseBirthDate(birthText);
  if (birthDate == null) return '出生日期格式应为 yyyy-MM-dd';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (birthDate.isAfter(today)) return '出生日期不能晚于今天';
  return null;
}

String? _validateRequiredNumberInRange(
  String raw, {
  required String fieldName,
  required double min,
  required double max,
}) {
  final text = raw.trim();
  if (text.isEmpty) return '请填写$fieldName';

  final value = double.tryParse(text);
  if (value == null) return '$fieldName格式不正确';
  if (value < min || value > max) {
    return '$fieldName需在 ${_formatRangeNumber(min)}-${_formatRangeNumber(max)} 之间';
  }
  return null;
}

String _formatRangeNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
