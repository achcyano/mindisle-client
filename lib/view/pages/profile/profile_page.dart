
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  static final route = AppRoute<void>(
    path: '/home/profile',
    builder: (_) => const ProfilePage(),
  );

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      if (message == _lastErrorMessage) return;
      _lastErrorMessage = message;

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      body: _buildBody(
        context: context,
        state: state,
        controller: controller,
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ProfileState state,
    required ProfileController controller,
  }) {
    if (state.isLoading && state.profile == null) {
      return const Center(child: CircularProgressIndicatorM3E());
    }
    if (state.profile == null) {
      return Center(
        child: FilledButton(
          onPressed: () => controller.initialize(refresh: true),
          child: const Text('Retry'),
        ),
      );
    }

    final profile = state.profile!;
    final formIdentity = [
      profile.userId,
      profile.fullName ?? '',
      profile.gender.name,
      profile.birthDate ?? '',
      profile.heightCm?.toString() ?? '',
      profile.weightKg?.toString() ?? '',
      profile.waistCm?.toString() ?? '',
      profile.diseaseHistory.join('|'),
    ].join('#');
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: const Text('Profile'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                _buildAvatarSelector(
                  context: context,
                  state: state,
                  onTapChangeAvatar: _showAvatarPickerSheet,
                ),
                const SizedBox(height: 18),
                Card(
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
                          onChanged: controller.setFullName,
                        ),
                        const SizedBox(height: 10),
                        _buildGenderField(
                          value: state.gender,
                          onChanged: controller.setGender,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          label: 'Birth date (yyyy-MM-dd)',
                          initialValue: state.birthDate,
                          textInputAction: TextInputAction.next,
                          onChanged: controller.setBirthDate,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          label: 'Height (cm)',
                          initialValue: state.heightCm,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: controller.setHeightCm,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          label: 'Weight (kg)',
                          initialValue: state.weightKg,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: controller.setWeightKg,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          label: 'Waist (cm)',
                          initialValue: state.waistCm,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: controller.setWaistCm,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          label: 'Medical history (one per line)',
                          initialValue: state.diseaseHistoryInput,
                          minLines: 3,
                          maxLines: 6,
                          textInputAction: TextInputAction.newline,
                          onChanged: controller.setDiseaseHistoryInput,
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: state.isSaving
                              ? null
                              : () => _saveProfile(controller),
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSelector({
    required BuildContext context,
    required ProfileState state,
    required VoidCallback onTapChangeAvatar,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: InkWell(
        onTap: state.isUploadingAvatar ? null : onTapChangeAvatar,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 66,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: state.avatarBytes == null
                    ? null
                    : MemoryImage(state.avatarBytes!),
                child: state.avatarBytes == null
                    ? Icon(
                        Icons.person_outline,
                        size: 42,
                        color: colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
              if (state.isUploadingAvatar)
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: const SizedBox(
                    width: 132,
                    height: 132,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicatorM3E(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

  Future<void> _saveProfile(ProfileController controller) async {
    final message = await controller.saveProfile();
    if (!mounted || message == null || message.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAvatarPickerSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;
    final message = await ref
        .read(profileControllerProvider.notifier)
        .pickAndUploadAvatar(source);
    if (!mounted || message == null || message.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

