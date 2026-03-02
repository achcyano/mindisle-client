import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';
import 'package:mindisle_client/features/medication/presentation/editor/medication_editor_state.dart';
import 'package:mindisle_client/view/pages/medicine/medication_presets.dart';
import 'package:mindisle_client/view/pages/medicine/widgets/dose_times_input.dart';
import 'package:mindisle_client/view/widget/app_dialog.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';
import 'package:mindisle_client/view/widget/settings_input_field.dart';

class MedicationFormFields extends StatelessWidget {
  const MedicationFormFields({
    required this.state,
    required this.enabled,
    required this.onDrugNameChanged,
    required this.onDoseAmountChanged,
    required this.onDoseUnitChanged,
    required this.onTabletStrengthAmountChanged,
    required this.onTabletStrengthUnitChanged,
    required this.onPickEndDate,
    required this.onAddDoseTime,
    required this.onRemoveDoseTime,
    super.key,
  });

  final MedicationEditorState state;
  final bool enabled;
  final ValueChanged<String> onDrugNameChanged;
  final ValueChanged<String> onDoseAmountChanged;
  final ValueChanged<MedicationDoseUnit> onDoseUnitChanged;
  final ValueChanged<String> onTabletStrengthAmountChanged;
  final ValueChanged<MedicationStrengthUnit> onTabletStrengthUnitChanged;
  final VoidCallback onPickEndDate;
  final Future<void> Function() onAddDoseTime;
  final ValueChanged<String> onRemoveDoseTime;

  static final TextInputFormatter _threeDecimalInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) return newValue;
        final ok = RegExp(r'^\d+(\.\d{0,3})?$').hasMatch(text);
        return ok ? newValue : oldValue;
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 6,
      children: [
        _buildDrugGroup(context),
        DoseTimesInput(
          values: state.doseTimes,
          enabled: enabled,
          onAddPressed: onAddDoseTime,
          onRemovePressed: onRemoveDoseTime,
        ),
        _buildDateGroup(),
      ],
    );
  }

  Widget _buildDrugGroup(BuildContext context) {
    return SettingsGroup(
      title: '药品信息',
      children: [
        const _FieldLabel(text: '药品名称'),
        SettingsInputField(
          value: state.drugName,
          enabled: enabled,
          hintText: '请输入药品名称（可手动输入）',
          maxLength: 200,
          onChanged: onDrugNameChanged,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        ),
        AppListTile(
          title: const Text('从列表选择药品'),
          subtitle: Text(
            _selectedPresetNameText(state.drugName),
          ),
          leading: const Icon(Icons.playlist_add_check_circle_outlined),
          trailingIcon: Icons.chevron_right,
          position: AppListTilePosition.single,
          onTap: enabled ? () => _pickPresetDrugName(context) : null,
        ),
        const Divider(height: 1, thickness: 0.2, indent: 16, endIndent: 16),
        const _FieldLabel(text: '每次剂量'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SettingsInputField(
                  value: state.doseAmount,
                  enabled: enabled,
                  hintText: '请输入数值',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_threeDecimalInputFormatter],
                  onChanged: onDoseAmountChanged,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              _DoseUnitSelector(
                enabled: enabled,
                selected: state.doseUnit,
                onChanged: onDoseUnitChanged,
              ),
            ],
          ),
        ),
        if (state.requiresTabletStrength) ...[
          const Divider(height: 1, thickness: 0.2, indent: 16, endIndent: 16),
          const _FieldLabel(text: '每片规格'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SettingsInputField(
                    value: state.tabletStrengthAmount,
                    enabled: enabled,
                    hintText: '请输入数值',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [_threeDecimalInputFormatter],
                    onChanged: onTabletStrengthAmountChanged,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                _StrengthUnitSelector(
                  enabled: enabled,
                  selected: state.tabletStrengthUnit,
                  onChanged: onTabletStrengthUnitChanged,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateGroup() {
    final title = state.endDate.trim().isEmpty ? '请选择结束日期' : state.endDate.trim();
    final subtitle = state.recordedDate.trim().isEmpty
        ? '结束日期'
        : '记录日期：${state.recordedDate}';

    return SettingsGroup(
      title: '疗程信息',
      children: [
        AppListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          leading: const Icon(Icons.event_outlined),
          trailingIcon: Icons.chevron_right,
          position: AppListTilePosition.single,
          onTap: enabled ? onPickEndDate : null,
        ),
      ],
    );
  }

  String _selectedPresetNameText(String drugName) {
    final value = drugName.trim();
    if (medicationPresetDrugNames.contains(value)) {
      return '已选择：$value';
    }
    return '共 ${medicationPresetDrugNames.length} 种可选药品';
  }

  Future<void> _pickPresetDrugName(BuildContext context) async {
    final selected = await showAppDialog<String>(
      context: context,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        final maxListHeight = screenHeight * 0.55;
        final listHeight = maxListHeight > 480 ? 480.0 : maxListHeight;
        return buildAppAlertDialog(
          title: const Text('选择药品（滚动可查看药品列表）'),
          content: SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: medicationPresetDrugNames.length,
              itemBuilder: (_, index) {
                final name = medicationPresetDrugNames[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  onTap: () => Navigator.of(dialogContext).pop(name),
                );
              },
            ),
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

    if (!context.mounted || selected == null) return;
    onDrugNameChanged(selected);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _DoseUnitSelector extends StatelessWidget {
  const _DoseUnitSelector({
    required this.enabled,
    required this.selected,
    required this.onChanged,
  });

  final bool enabled;
  final MedicationDoseUnit selected;
  final ValueChanged<MedicationDoseUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MedicationDoseUnit>(
      segments: const [
        ButtonSegment(value: MedicationDoseUnit.mg, label: Text('mg')),
        ButtonSegment(value: MedicationDoseUnit.g, label: Text('g')),
        ButtonSegment(value: MedicationDoseUnit.tablet, label: Text('片')),
      ],
      selected: <MedicationDoseUnit>{selected},
      onSelectionChanged: enabled ? (values) => onChanged(values.first) : null,
      showSelectedIcon: false,
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _StrengthUnitSelector extends StatelessWidget {
  const _StrengthUnitSelector({
    required this.enabled,
    required this.selected,
    required this.onChanged,
  });

  final bool enabled;
  final MedicationStrengthUnit selected;
  final ValueChanged<MedicationStrengthUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MedicationStrengthUnit>(
      segments: const [
        ButtonSegment(value: MedicationStrengthUnit.mg, label: Text('mg')),
        ButtonSegment(value: MedicationStrengthUnit.g, label: Text('g')),
      ],
      selected: <MedicationStrengthUnit>{selected},
      onSelectionChanged: enabled ? (values) => onChanged(values.first) : null,
      showSelectedIcon: false,
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
