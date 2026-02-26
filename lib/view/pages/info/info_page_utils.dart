import 'package:flutter/services.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';

abstract final class InfoPageUtils {
  static const List<String> diseaseHistoryOptions = <String>[
    '其它',
    '肠胃炎',
    '腹泻',
    '便秘',
    '过敏性结膜炎',
    '高血压',
    '糖尿病',
    '高脂血症',
    '冠心病',
    '脑梗死',
    '失眠',
    '哮喘',
  ];

  static final TextInputFormatter twoDecimalInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) return newValue;
        final ok = RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(text);
        return ok ? newValue : oldValue;
      });

  static String displayPhone(ProfileState state) {
    final phone = state.phone.trim();
    if (phone.isEmpty) return '未绑定手机号';
    if (RegExp(r'^\d{11}$').hasMatch(phone)) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  static String displayBirthDate(ProfileState state) {
    final text = effectiveBirthDateText(state);
    if (text.isEmpty) return '未设置';

    final parsed = tryParseBirthDate(text);
    if (parsed == null) return text;
    return '${parsed.year}年${parsed.month}月${parsed.day}日';
  }

  static String displayGender(UserGender gender) {
    return switch (gender) {
      UserGender.male => '男',
      UserGender.female => '女',
      UserGender.other => '其他',
      UserGender.unknown => '未设置',
    };
  }

  static String effectiveBirthDateText(ProfileState state) {
    return (state.birthDate.isNotEmpty
            ? state.birthDate
            : (state.profile?.birthDate ?? ''))
        .trim();
  }

  static DateTime? tryParseBirthDate(String value) {
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

  static String formatBirthDate(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  static List<String> diseaseHistoryEntries(ProfileState state) {
    final raw = state.diseaseHistoryInput.trim();
    if (raw.isEmpty) return const <String>[];
    return normalizeDiseaseHistoryTokens(
      raw.split(RegExp(r'[\n,，、;；]+')),
    );
  }

  static List<String> normalizeDiseaseHistoryTokens(Iterable<String> source) {
    final result = <String>[];
    final dedup = <String>{};
    for (final raw in source) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      if (dedup.contains(token)) continue;
      dedup.add(token);
      result.add(token);
    }
    return result;
  }
}
