import 'package:flutter/material.dart';
import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';
import 'package:mindisle_client/view/pages/medicine/widgets/medication_card_tile.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';

class MedicationGroupSection extends StatelessWidget {
  const MedicationGroupSection({
    required this.title,
    required this.items,
    required this.deletingMedicationId,
    required this.onTapItem,
    required this.onDeleteItem,
    super.key,
  });

  final String title;
  final List<MedicationRecord> items;
  final int? deletingMedicationId;
  final ValueChanged<MedicationRecord> onTapItem;
  final ValueChanged<MedicationRecord> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: title,
      children: items.isEmpty ? _buildEmpty(context) : _buildItems(),
    );
  }

  List<Widget> _buildEmpty(BuildContext context) {
    return [
      AppListTile(
        position: AppListTilePosition.single,
        title: Text(
          '暂无记录',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: null,
      ),
    ];
  }

  List<Widget> _buildItems() {
    final tiles = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final position = switch (i) {
        0 when items.length == 1 => AppListTilePosition.single,
        0 => AppListTilePosition.first,
        _ when i == items.length - 1 => AppListTilePosition.last,
        _ => AppListTilePosition.middle,
      };
      final item = items[i];
      tiles.add(
        MedicationCardTile(
          item: item,
          position: position,
          isDeleting: deletingMedicationId == item.medicationId,
          onTap: () => onTapItem(item),
          onDelete: () => onDeleteItem(item),
        ),
      );
    }
    return tiles;
  }
}
