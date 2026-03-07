import 'package:patient/features/medication/domain/entities/medication_entities.dart';

final class MedicationListState {
  const MedicationListState({
    this.initialized = false,
    this.isLoading = false,
    this.isRefreshing = false,
    this.deletingMedicationId,
    this.items = const <MedicationRecord>[],
    this.errorMessage,
  });

  final bool initialized;
  final bool isLoading;
  final bool isRefreshing;
  final int? deletingMedicationId;
  final List<MedicationRecord> items;
  final String? errorMessage;

  List<MedicationRecord> get activeItems {
    return items.where(_isActiveRecord).toList(growable: false);
  }

  List<MedicationRecord> get inactiveItems {
    return items.where((item) => !_isActiveRecord(item)).toList(growable: false);
  }

  MedicationListState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isRefreshing,
    Object? deletingMedicationId = _sentinel,
    List<MedicationRecord>? items,
    Object? errorMessage = _sentinel,
  }) {
    return MedicationListState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      deletingMedicationId: identical(deletingMedicationId, _sentinel)
          ? this.deletingMedicationId
          : deletingMedicationId as int?,
      items: items ?? this.items,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool _isActiveRecord(MedicationRecord record) {
    if (record.isActive) return true;

    final recordedDate = _tryParseDate(record.recordedDate);
    final endDate = _tryParseDate(record.endDate);
    if (recordedDate == null || endDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(recordedDate) && !today.isAfter(endDate);
  }

  DateTime? _tryParseDate(String raw) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw.trim());
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
}

const Object _sentinel = Object();
