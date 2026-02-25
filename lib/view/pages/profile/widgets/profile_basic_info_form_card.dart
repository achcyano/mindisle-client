import 'package:flutter/material.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

@immutable
class ProfileBasicInfoFormData {
  const ProfileBasicInfoFormData({
    required this.formIdentity,
    required this.isSaving,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.waistCm,
    required this.diseaseHistoryInput,
  });

  factory ProfileBasicInfoFormData.fromState(ProfileState state) {
    final profile = state.profile;
    return ProfileBasicInfoFormData(
      formIdentity: [
        profile?.userId ?? 0,
        state.fullName,
        state.gender.name,
        state.birthDate,
        state.heightCm,
        state.weightKg,
        state.waistCm,
        state.diseaseHistoryInput,
      ].join('#'),
      isSaving: state.isSaving,
      fullName: state.fullName,
      gender: state.gender,
      birthDate: state.birthDate,
      heightCm: state.heightCm,
      weightKg: state.weightKg,
      waistCm: state.waistCm,
      diseaseHistoryInput: state.diseaseHistoryInput,
    );
  }

  final String formIdentity;
  final bool isSaving;
  final String fullName;
  final UserGender gender;
  final String birthDate;
  final String heightCm;
  final String weightKg;
  final String waistCm;
  final String diseaseHistoryInput;
}

@immutable
class ProfileBasicInfoFormActions {
  const ProfileBasicInfoFormActions({
    required this.onFullNameChanged,
    required this.onGenderChanged,
    required this.onBirthDateChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onWaistChanged,
    required this.onDiseaseHistoryChanged,
    required this.onSavePressed,
  });

  factory ProfileBasicInfoFormActions.fromController({
    required ProfileController controller,
    required VoidCallback? onSavePressed,
  }) {
    return ProfileBasicInfoFormActions(
      onFullNameChanged: controller.setFullName,
      onGenderChanged: controller.setGender,
      onBirthDateChanged: controller.setBirthDate,
      onHeightChanged: controller.setHeightCm,
      onWeightChanged: controller.setWeightKg,
      onWaistChanged: controller.setWaistCm,
      onDiseaseHistoryChanged: controller.setDiseaseHistoryInput,
      onSavePressed: onSavePressed,
    );
  }

  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<UserGender> onGenderChanged;
  final ValueChanged<String> onBirthDateChanged;
  final ValueChanged<String> onHeightChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onWaistChanged;
  final ValueChanged<String> onDiseaseHistoryChanged;
  final VoidCallback? onSavePressed;
}

class ProfileBasicInfoFormCard extends StatelessWidget {
  const ProfileBasicInfoFormCard({
    super.key,
    required this.data,
    required this.actions,
  });

  final ProfileBasicInfoFormData data;
  final ProfileBasicInfoFormActions actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        key: ValueKey(data.formIdentity),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Basic Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Name',
              initialValue: data.fullName,
              textInputAction: TextInputAction.next,
              onChanged: actions.onFullNameChanged,
            ),
            const SizedBox(height: 10),
            _buildGenderField(
              value: data.gender,
              onChanged: actions.onGenderChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Birth date (yyyy-MM-dd)',
              initialValue: data.birthDate,
              textInputAction: TextInputAction.next,
              onChanged: actions.onBirthDateChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Height (cm)',
              initialValue: data.heightCm,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onChanged: actions.onHeightChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Weight (kg)',
              initialValue: data.weightKg,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onChanged: actions.onWeightChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Waist (cm)',
              initialValue: data.waistCm,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onChanged: actions.onWaistChanged,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Medical history (one per line)',
              initialValue: data.diseaseHistoryInput,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              onChanged: actions.onDiseaseHistoryChanged,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: actions.onSavePressed,
              icon: data.isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: FittedBox(child: CircularProgressIndicatorM3E()),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(data.isSaving ? 'Saving...' : 'Save'),
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
