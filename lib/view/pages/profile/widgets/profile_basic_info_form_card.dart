import 'package:flutter/material.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ProfileBasicInfoFormCard extends StatelessWidget {
  const ProfileBasicInfoFormCard({
    super.key,
    required this.formIdentity,
    required this.state,
    required this.onFullNameChanged,
    required this.onGenderChanged,
    required this.onBirthDateChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onWaistChanged,
    required this.onDiseaseHistoryChanged,
    required this.onSavePressed,
  });

  final String formIdentity;
  final ProfileState state;
  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<UserGender> onGenderChanged;
  final ValueChanged<String> onBirthDateChanged;
  final ValueChanged<String> onHeightChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onWaistChanged;
  final ValueChanged<String> onDiseaseHistoryChanged;
  final VoidCallback? onSavePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        key: ValueKey(formIdentity),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Basic Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Name',
              initialValue: state.fullName,
              textInputAction: TextInputAction.next,
              onChanged: onFullNameChanged,
            ),
            const SizedBox(height: 10),
            _buildGenderField(
              value: state.gender,
              onChanged: onGenderChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Birth date (yyyy-MM-dd)',
              initialValue: state.birthDate,
              textInputAction: TextInputAction.next,
              onChanged: onBirthDateChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Height (cm)',
              initialValue: state.heightCm,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onChanged: onHeightChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Weight (kg)',
              initialValue: state.weightKg,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onChanged: onWeightChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Waist (cm)',
              initialValue: state.waistCm,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onChanged: onWaistChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Medical history (one per line)',
              initialValue: state.diseaseHistoryInput,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              onChanged: onDiseaseHistoryChanged,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onSavePressed,
              icon: state.isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: FittedBox(
                        child: CircularProgressIndicatorM3E(),
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(state.isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField({
    required UserGender value,
    required ValueChanged<UserGender> onChanged,
  }) {
    return DropdownButtonFormField<UserGender>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Gender'),
      items: const [
        DropdownMenuItem(value: UserGender.unknown, child: Text('Unknown')),
        DropdownMenuItem(value: UserGender.male, child: Text('Male')),
        DropdownMenuItem(value: UserGender.female, child: Text('Female')),
        DropdownMenuItem(value: UserGender.other, child: Text('Other')),
      ],
      onChanged: (next) {
        if (next == null) return;
        onChanged(next);
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int? minLines,
    int? maxLines,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      onChanged: onChanged,
    );
  }
}
