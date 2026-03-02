import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/medication/presentation/editor/medication_editor_args.dart';
import 'package:mindisle_client/features/medication/presentation/editor/medication_editor_controller.dart';
import 'package:mindisle_client/features/medication/presentation/editor/medication_editor_state.dart';
import 'package:mindisle_client/view/pages/medicine/widgets/medication_form_fields.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/app_dialog.dart';

class MedicationEditorPage extends ConsumerStatefulWidget {
  const MedicationEditorPage({required this.args, super.key});

  final MedicationEditorArgs args;

  static final route = AppRouteArg<bool, MedicationEditorArgs>(
    path: '/home/medicine/editor',
    builder: (args) => MedicationEditorPage(args: args),
  );

  @override
  ConsumerState<MedicationEditorPage> createState() => _MedicationEditorPageState();
}

class _MedicationEditorPageState extends ConsumerState<MedicationEditorPage> {
  String? _lastErrorMessage;

  @override
  Widget build(BuildContext context) {
    ref.listen<MedicationEditorState>(
      medicationEditorControllerProvider(widget.args),
      (previous, next) {
        final message = next.errorMessage;
        if (message == null || message.isEmpty) return;
        if (message == _lastErrorMessage) return;
        _lastErrorMessage = message;
        _showSnack(message);
      },
    );

    final state = ref.watch(medicationEditorControllerProvider(widget.args));
    final controller = ref.read(
      medicationEditorControllerProvider(widget.args).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.isEditing ? '编辑药品' : '添加药品'),
        actions: [
          TextButton(
            onPressed: state.isSubmitting ? null : () => _submit(controller),
            child: const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: MedicationFormFields(
            state: state,
            enabled: !state.isSubmitting,
            onDrugNameChanged: controller.setDrugName,
            onDoseAmountChanged: controller.setDoseAmount,
            onDoseUnitChanged: controller.setDoseUnit,
            onTabletStrengthAmountChanged: controller.setTabletStrengthAmount,
            onTabletStrengthUnitChanged: controller.setTabletStrengthUnit,
            onPickEndDate: () => _pickEndDate(state, controller),
            onAddDoseTime: () => _pickDoseTime(state, controller),
            onRemoveDoseTime: controller.removeDoseTime,
          ),
        ),
      ),
    );
  }

  Future<void> _submit(MedicationEditorController controller) async {
    final ok = await controller.submit();
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDoseTime(
    MedicationEditorState state,
    MedicationEditorController controller,
  ) async {
    final now = TimeOfDay.now();
    final initialTime = _parseTime(state.doseTimes.isEmpty ? null : state.doseTimes.last) ??
        now;

    final picked = await showAppDialog<TimeOfDay>(
      context: context,
      builder: (_) {
        return TimePickerDialog(
          initialTime: initialTime,
          helpText: '选择用药时间',
          cancelText: '取消',
          confirmText: '确定',
        );
      },
    );

    if (!mounted || picked == null) return;

    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final message = controller.addDoseTime(value);
    if (message != null) {
      _showSnack(message);
    }
  }

  Future<void> _pickEndDate(
    MedicationEditorState state,
    MedicationEditorController controller,
  ) async {
    final now = DateTime.now();
    final fallbackFirstDate = DateTime(1900, 1, 1);
    final recordedDate = _parseDate(state.recordedDate);
    final firstDate = recordedDate ?? fallbackFirstDate;
    final lastDate = DateTime(now.year + 50, 12, 31);

    var initialDate =
        _parseDate(state.endDate) ?? _defaultDateAfterOneMonth(from: now);
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showAppDialog<DateTime>(
      context: context,
      builder: (_) {
        return DatePickerDialog(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: '选择结束日期',
          cancelText: '取消',
          confirmText: '确定',
        );
      },
    );

    if (!mounted || picked == null) return;

    final date = DateTime(picked.year, picked.month, picked.day);
    controller.setEndDate(_formatDate(date));
  }

  DateTime? _parseDate(String raw) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw.trim());
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

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  DateTime _defaultDateAfterOneMonth({required DateTime from}) {
    final year = from.month == 12 ? from.year + 1 : from.year;
    final month = from.month == 12 ? 1 : from.month + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = from.day > lastDay ? lastDay : from.day;
    return DateTime(year, month, day);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
