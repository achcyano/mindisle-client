import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:patient/features/medication/domain/entities/medication_entities.dart';

class TodayMedicationCard extends StatelessWidget {
  const TodayMedicationCard({
    super.key,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.onTapManage,
    required this.onRetry,
  });

  final List<MedicationRecord> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTapManage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final hasData = items.isNotEmpty;
    final hasError = (errorMessage ?? '').trim().isNotEmpty;

    if (!hasData && hasError && !isLoading) {
      return RetryErrorCard(
        title: '用药数据加载失败',
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (!hasData && isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(
            children: const [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('正在加载今日用药...')),
            ],
          ),
        ),
      );
    }

    if (!hasData) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTapManage,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.75,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('今日用药')),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                _MedicationLine(item: items[index]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationLine extends StatelessWidget {
  const _MedicationLine({required this.item});

  final MedicationRecord item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeText = item.doseTimes.join(' / ');
    final doseText = _compactDoseText(item);
    final timeStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.62),
    );

    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(text: '${item.drugName}  $doseText'),
          if (timeText.isNotEmpty)
            TextSpan(text: '  $timeText', style: timeStyle),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _compactDoseText(MedicationRecord record) {
    final amount = _formatAmount(record.doseAmount);
    if (record.doseUnit == MedicationDoseUnit.tablet) {
      return '$amount片';
    }

    final unit = switch (record.doseUnit) {
      MedicationDoseUnit.g => 'g',
      MedicationDoseUnit.mg => 'mg',
      MedicationDoseUnit.tablet => '片',
    };
    return '$amount$unit';
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
