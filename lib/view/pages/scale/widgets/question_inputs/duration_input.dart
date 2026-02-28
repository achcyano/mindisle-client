import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_answer_draft.dart';
import 'package:mindisle_client/view/pages/scale/widgets/question_inputs/question_input_factory.dart';

class DurationInput extends StatelessWidget {
  const DurationInput({
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
    final display = _formatDuration(draft?.durationMinutes);
    return _DurationPickerField(
      icon: Icons.hourglass_bottom_rounded,
      label: display ?? '请选择时长',
      enabled: enabled,
      onTap: () async {
        final minutes = await _pickDurationMinutes(
          context: context,
          initialMinutes: draft?.durationMinutes ?? 60,
        );
        if (minutes == null) return;
        onDraftChanged(
          ScaleAnswerDraft.duration(durationMinutes: minutes),
          true,
        );
      },
    );
  }

  Future<int?> _pickDurationMinutes({
    required BuildContext context,
    required int initialMinutes,
  }) async {
    final maxMinutes = 23 * 60 + 59;
    final clamped = initialMinutes.clamp(0, maxMinutes);

    return showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var selectedMinutes = clamped;
        return StatefulBuilder(
          builder: (innerContext, setInnerState) {
            final initialDuration = Duration(minutes: selectedMinutes);
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: initialDuration,
                      onTimerDurationChanged: (duration) {
                        setInnerState(() {
                          selectedMinutes = duration.inMinutes;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop(selectedMinutes);
                            },
                            child: const Text('确定'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _formatDuration(int? totalMinutes) {
    if (totalMinutes == null || totalMinutes < 0) return null;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) {
      return '$minutes分钟';
    }
    if (minutes == 0) {
      return '$hours小时';
    }
    return '$hours小时$minutes分钟';
  }
}

class _DurationPickerField extends StatelessWidget {
  const _DurationPickerField({
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
