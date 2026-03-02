import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';
import 'package:mindisle_client/features/medication/presentation/editor/medication_editor_args.dart';
import 'package:mindisle_client/features/medication/presentation/editor/medication_editor_state.dart';
import 'package:mindisle_client/features/medication/presentation/providers/medication_providers.dart';

final medicationEditorControllerProvider = StateNotifierProvider.autoDispose
    .family<MedicationEditorController, MedicationEditorState, MedicationEditorArgs>((
      ref,
      args,
    ) {
      return MedicationEditorController(ref, args);
    });

final class MedicationEditorController extends StateNotifier<MedicationEditorState> {
  MedicationEditorController(this._ref, this._args)
    : super(MedicationEditorState.initial(_args.initial));

  final Ref _ref;
  final MedicationEditorArgs _args;

  static final RegExp _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final RegExp _decimal3Pattern = RegExp(r'^\d+(\.\d{1,3})?$');
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  void setDrugName(String value) {
    state = state.copyWith(drugName: value, errorMessage: null);
  }

  void setDoseAmount(String value) {
    state = state.copyWith(doseAmount: value, errorMessage: null);
  }

  void setDoseUnit(MedicationDoseUnit value) {
    state = state.copyWith(doseUnit: value, errorMessage: null);
  }

  void setTabletStrengthAmount(String value) {
    state = state.copyWith(tabletStrengthAmount: value, errorMessage: null);
  }

  void setTabletStrengthUnit(MedicationStrengthUnit value) {
    state = state.copyWith(tabletStrengthUnit: value, errorMessage: null);
  }

  void setEndDate(String value) {
    state = state.copyWith(endDate: value, errorMessage: null);
  }

  String? addDoseTime(String value) {
    final normalized = _normalizeTime(value);
    if (normalized == null) return '时间格式应为 HH:mm';

    final exists = state.doseTimes.contains(normalized);
    if (exists) return '该时间已添加';

    if (state.doseTimes.length >= 16) {
      return '每天用药时间最多 16 个';
    }

    final next = <String>[...state.doseTimes, normalized]..sort();
    state = state.copyWith(doseTimes: next, errorMessage: null);
    return null;
  }

  void removeDoseTime(String value) {
    final next = state.doseTimes
        .where((item) => item != value)
        .toList(growable: false);
    state = state.copyWith(doseTimes: next, errorMessage: null);
  }

  String? validate() {
    final drugName = state.drugName.trim();
    if (drugName.isEmpty) return '请填写药品名称';
    if (drugName.length > 200) return '药品名称不能超过 200 个字符';
    if (_controlChars.hasMatch(drugName)) return '药品名称包含非法字符';

    if (state.doseTimes.isEmpty) return '请至少添加一个用药时间';
    if (state.doseTimes.length > 16) return '每天用药时间最多 16 个';
    if (state.doseTimes.any((item) => !_timePattern.hasMatch(item))) {
      return '用药时间格式应为 HH:mm';
    }

    final endDateText = state.endDate.trim();
    if (endDateText.isEmpty) return '请选择结束日期';

    final endDate = _parseDate(endDateText);
    if (endDate == null) return '结束日期格式应为 yyyy-MM-dd';

    final recordedText = state.recordedDate.trim();
    if (recordedText.isNotEmpty) {
      final recordedDate = _parseDate(recordedText);
      if (recordedDate != null && endDate.isBefore(recordedDate)) {
        return '结束日期不能早于记录日期';
      }
    }

    final doseAmount = _parsePositiveAmount(state.doseAmount, fieldName: '每次剂量');
    if (doseAmount.$2 != null) return doseAmount.$2;

    if (state.requiresTabletStrength) {
      final tabletStrength = _parsePositiveAmount(
        state.tabletStrengthAmount,
        fieldName: '每片规格',
      );
      if (tabletStrength.$2 != null) return tabletStrength.$2;
    }

    return null;
  }

  Future<bool> submit() async {
    if (state.isSubmitting) return false;

    final validationMessage = validate();
    if (validationMessage != null) {
      state = state.copyWith(errorMessage: validationMessage);
      return false;
    }

    final payload = UpsertMedicationPayload(
      drugName: state.drugName.trim(),
      doseTimes: _normalizedDoseTimes(state.doseTimes),
      endDate: state.endDate.trim(),
      doseAmount: double.parse(state.doseAmount.trim()),
      doseUnit: state.doseUnit,
      tabletStrengthAmount: state.requiresTabletStrength
          ? double.parse(state.tabletStrengthAmount.trim())
          : null,
      tabletStrengthUnit: state.requiresTabletStrength
          ? state.tabletStrengthUnit
          : null,
    );

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    if (_args.isEditing && state.medicationId != null) {
      final result = await _ref
          .read(updateMedicationUseCaseProvider)
          .execute(medicationId: state.medicationId!, payload: payload);
      return switch (result) {
        Failure<MedicationRecord>(error: final error) => _submitFailure(error.message),
        Success<MedicationRecord>(data: final data) => _submitSuccess(data),
      };
    }

    final result = await _ref.read(createMedicationUseCaseProvider).execute(payload);
    return switch (result) {
      Failure<MedicationRecord>(error: final error) => _submitFailure(error.message),
      Success<MedicationRecord>(data: final data) => _submitSuccess(data),
    };
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  bool _submitFailure(String message) {
    state = state.copyWith(isSubmitting: false, errorMessage: message);
    return false;
  }

  bool _submitSuccess(MedicationRecord record) {
    state = state.copyWith(
      medicationId: record.medicationId,
      recordedDate: record.recordedDate,
      drugName: record.drugName,
      doseTimes: record.doseTimes,
      endDate: record.endDate,
      doseAmount: _formatAmount(record.doseAmount),
      doseUnit: record.doseUnit,
      tabletStrengthAmount: _formatAmount(record.tabletStrengthAmount),
      tabletStrengthUnit: record.tabletStrengthUnit ?? state.tabletStrengthUnit,
      isSubmitting: false,
      errorMessage: null,
    );
    return true;
  }

  String? _normalizeTime(String raw) {
    final text = raw.trim();
    if (!_timePattern.hasMatch(text)) return null;
    return text;
  }

  List<String> _normalizedDoseTimes(List<String> source) {
    final dedup = <String>{};
    final normalized = <String>[];
    for (final raw in source) {
      final value = _normalizeTime(raw);
      if (value == null || dedup.contains(value)) continue;
      dedup.add(value);
      normalized.add(value);
    }
    normalized.sort();
    return normalized;
  }

  (double?, String?) _parsePositiveAmount(
    String raw, {
    required String fieldName,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return (null, '请填写$fieldName');
    if (!_decimal3Pattern.hasMatch(text)) return (null, '$fieldName格式不正确');

    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return (null, '$fieldName格式不正确');
    if (value <= 0 || value > 100000) {
      return (null, '$fieldName需大于0且不超过100000');
    }
    return (value, null);
  }

  DateTime? _parseDate(String raw) {
    final match = _datePattern.firstMatch(raw);
    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String _formatAmount(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
