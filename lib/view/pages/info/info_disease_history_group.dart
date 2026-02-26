import 'package:flutter/material.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/info/info_page_utils.dart';
import 'package:mindisle_client/view/pages/info/info_page_validation.dart';
import 'package:mindisle_client/view/widget/app_dialog.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';

class InfoDiseaseHistoryGroup extends StatelessWidget {
  const InfoDiseaseHistoryGroup({
    required this.state,
    required this.onDiseaseHistoryChanged,
    required this.onShowSnack,
    super.key,
  });

  final ProfileState state;
  final ValueChanged<String> onDiseaseHistoryChanged;
  final ValueChanged<String> onShowSnack;

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: '疾病史',
      children: _buildDiseaseHistoryEntries(context),
    );
  }

  List<Widget> _buildDiseaseHistoryEntries(BuildContext context) {
    final entries = InfoPageUtils.diseaseHistoryEntries(state);
    final tiles = <Widget>[];

    if (entries.isNotEmpty) {
      for (var i = 0; i < entries.length; i++) {
        tiles.add(
          AppListTile(
            title: Text(entries[i]),
            position: i == 0
                ? AppListTilePosition.first
                : AppListTilePosition.middle,
            paddingBottom: 0,
            paddingTop: 0,
            trailing: IconButton(
              tooltip: '删除',
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              onPressed: state.isSaving
                  ? null
                  : () => _removeDiseaseHistory(entry: entries[i]),
            ),
            onTap: null,
          ),
        );
      }
    }

    tiles.add(
      AppListTile(
        title: Text(
          '添加',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        leading: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
        ),
        position: AppListTilePosition.last,
        onTap: state.isSaving ? null : () => _addDiseaseHistory(context),
      ),
    );

    return tiles;
  }

  Future<void> _addDiseaseHistory(BuildContext context) async {
    final selected = await _pickDiseaseHistoryOption(context);
    if (!context.mounted || selected == null) return;

    var entry = selected;
    if (selected == '其它') {
      final custom = await _inputCustomDiseaseHistory(context);
      if (!context.mounted || custom == null) return;
      entry = custom;
    }

    final validationMessage = validateDiseaseHistoryEntry(entry);
    if (validationMessage != null) {
      onShowSnack(validationMessage);
      return;
    }

    final entries = InfoPageUtils.diseaseHistoryEntries(state);
    if (entries.contains(entry)) {
      onShowSnack('该疾病已录入');
      return;
    }
    if (entries.length >= 50) {
      onShowSnack('疾病史最多可填写 50 项');
      return;
    }

    entries.add(entry);
    onDiseaseHistoryChanged(entries.join('\n'));
  }

  void _removeDiseaseHistory({required String entry}) {
    final entries = InfoPageUtils.diseaseHistoryEntries(state);
    final removed = entries.remove(entry);
    if (!removed) return;
    onDiseaseHistoryChanged(entries.join('\n'));
  }

  Future<String?> _pickDiseaseHistoryOption(BuildContext context) async {
    return showAppDialog<String>(
      context: context,
      builder: (dialogContext) {
        return buildAppAlertDialog(
          title: const Text('添加疾病史'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in InfoPageUtils.diseaseHistoryOptions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  onTap: () => Navigator.of(dialogContext).pop(option),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _inputCustomDiseaseHistory(BuildContext context) async {
    var inputValue = '';
    final value = await showAppDialog<String>(
      context: context,
      builder: (dialogContext) {
        return buildAppAlertDialog(
          title: const Text('填写其它疾病'),
          content: TextField(
            autofocus: true,
            maxLength: 200,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              inputValue = value;
            },
            onSubmitted: (_) {
              Navigator.of(dialogContext).pop(inputValue.trim());
            },
            decoration: const InputDecoration(
              hintText: '请输入疾病名称',
              border: OutlineInputBorder(),
              isDense: true,
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(inputValue.trim());
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      onShowSnack('请输入疾病名称');
      return null;
    }
    return trimmed;
  }
}
