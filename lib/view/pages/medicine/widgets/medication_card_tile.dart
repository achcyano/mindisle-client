import 'package:flutter/material.dart';
import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';

class MedicationCardTile extends StatelessWidget {
  const MedicationCardTile({
    required this.item,
    required this.position,
    required this.onTap,
    required this.onDelete,
    this.isDeleting = false,
    super.key,
  });

  final MedicationRecord item;
  final AppListTilePosition position;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppListTile(
      position: position,
      leading: Icon(item.isActive ? Icons.medication_rounded : Icons.history),
      title: Text(item.drugName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_doseText(item)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final time in item.doseTimes)
                Chip(
                  label: Text(time),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('结束日期：${item.endDate}'),
        ],
      ),
      trailing: isDeleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: '删除',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
            ),
      onTap: onTap,
      paddingTop: 12,
      paddingBottom: 12,
    );
  }

  String _doseText(MedicationRecord record) {
    final amount = _formatAmount(record.doseAmount);
    final doseUnitLabel = _doseUnitLabel(record.doseUnit);

    if (record.doseUnit == MedicationDoseUnit.tablet) {
      final strengthAmount = _formatAmount(record.tabletStrengthAmount);
      final strengthUnitLabel = _strengthUnitLabel(record.tabletStrengthUnit);
      if (strengthAmount.isNotEmpty && strengthUnitLabel.isNotEmpty) {
        return '每次 $amount $doseUnitLabel（每片 $strengthAmount $strengthUnitLabel）';
      }
    }
    return '每次 $amount $doseUnitLabel';
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

  String _doseUnitLabel(MedicationDoseUnit unit) {
    return switch (unit) {
      MedicationDoseUnit.mg => 'mg',
      MedicationDoseUnit.g => 'g',
      MedicationDoseUnit.tablet => '片',
    };
  }

  String _strengthUnitLabel(MedicationStrengthUnit? unit) {
    return switch (unit) {
      MedicationStrengthUnit.mg => 'mg',
      MedicationStrengthUnit.g => 'g',
      null => '',
    };
  }
}
