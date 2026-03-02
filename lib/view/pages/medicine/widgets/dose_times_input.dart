import 'package:flutter/material.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';

class DoseTimesInput extends StatelessWidget {
  const DoseTimesInput({
    required this.values,
    required this.enabled,
    required this.onAddPressed,
    required this.onRemovePressed,
    super.key,
  });

  final List<String> values;
  final bool enabled;
  final Future<void> Function() onAddPressed;
  final ValueChanged<String> onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final hasValues = values.isNotEmpty;

    return SettingsGroup(
      title: '每天用药时间',
      children: [
        if (hasValues)
          ..._buildValueTiles(context),
        AppListTile(
          title: Text(
            '添加时间',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          leading: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.primary,
          ),
          position: AppListTilePosition.last,
          onTap: enabled ? onAddPressed : null,
        ),
      ],
    );
  }

  List<Widget> _buildValueTiles(BuildContext context) {
    final tiles = <Widget>[];

    for (var i = 0; i < values.length; i++) {
      final position = i == 0 ? AppListTilePosition.first : AppListTilePosition.middle;
      final value = values[i];
      tiles.add(
        AppListTile(
          title: Text(value),
          leading: const Icon(Icons.schedule_outlined),
          position: position,
          trailing: IconButton(
            tooltip: '删除',
            onPressed: enabled ? () => onRemovePressed(value) : null,
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
          ),
          onTap: null,
        ),
      );
    }

    return tiles;
  }
}
