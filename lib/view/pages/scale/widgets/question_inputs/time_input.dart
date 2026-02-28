import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/question_input_factory.dart';

class TimeInput extends StatelessWidget {
  const TimeInput({
    required this.draft,
    required this.enabled,
    required this.onDraftChanged,
    super.key,
  });

  final ScaleAnswerDraft? draft;
  final bool enabled;
  final ScaleAnswerDraftChanged onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final display = draft?.timeValue?.trim();
    final hasValue = display != null && display.isNotEmpty;

    return _PickerField(
      icon: Icons.schedule_rounded,
      label: hasValue ? display : '请选择时间',
      enabled: enabled,
      onTap: () async {
        final now = TimeOfDay.now();
        final parsed = _parseTime(display);
        final picked = await showTimePicker(
          context: context,
          initialTime: parsed ?? now,
        );
        if (picked == null) return;
        final value =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        onDraftChanged(ScaleAnswerDraft.time(timeValue: value), true);
      },
    );
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
