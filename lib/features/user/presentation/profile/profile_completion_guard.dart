import 'package:mindisle_client/features/user/domain/entities/user_basic_profile.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';

bool isBasicProfileComplete(UserBasicProfile profile) {
  return basicProfileIncompleteReason(profile) == null;
}

String? basicProfileIncompleteReason(UserBasicProfile profile) {
  final fullName = (profile.fullName ?? '').trim();
  if (fullName.isEmpty) return '姓名未填写';
  if (fullName.length > 200) return '姓名超长';
  if (_containsControlChars(fullName)) return '姓名包含非法字符';

  if (profile.gender == UserGender.unknown) return '性别未填写';

  final birthDateText = (profile.birthDate ?? '').trim();
  if (birthDateText.isEmpty) return '出生日期未填写';
  final birthDate = _tryParseBirthDate(birthDateText);
  if (birthDate == null) return '出生日期格式错误';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (birthDate.isAfter(today)) return '出生日期晚于今天';

  if (!_isInRange(profile.heightCm, min: 50, max: 260)) return '身高未填写或不合法';
  if (!_isInRange(profile.weightKg, min: 10, max: 500)) return '体重未填写或不合法';
  if (!_isInRange(profile.waistCm, min: 30, max: 220)) return '腰围未填写或不合法';

  return null;
}

bool _containsControlChars(String value) {
  return RegExp(r'[\x00-\x1F\x7F]').hasMatch(value);
}

DateTime? _tryParseBirthDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;

  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return null;

  final candidate = DateTime(year, month, day);
  if (candidate.year != year ||
      candidate.month != month ||
      candidate.day != day) {
    return null;
  }
  return candidate;
}

bool _isInRange(
  double? value, {
  required double min,
  required double max,
}) {
  if (value == null) return false;
  return value >= min && value <= max;
}
