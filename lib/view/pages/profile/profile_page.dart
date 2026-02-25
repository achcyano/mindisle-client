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
      appBar: AppBar(title: const Text('个人资料')),
      body: SafeArea(
        child: _buildBody(
          context: context,
          state: state,
          controller: controller,
        ),
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
          child: const Text('重试'),
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

    return RefreshIndicator(
      onRefresh: () => controller.initialize(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          _buildAvatarCard(
            context: context,
            state: state,
            onTapChangeAvatar: _showAvatarPickerSheet,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              key: ValueKey(formIdentity),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('基本资料', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: '姓名',
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
                    label: '出生日期（yyyy-MM-dd）',
                    initialValue: state.birthDate,
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setBirthDate,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    label: '身高（cm）',
                    initialValue: state.heightCm,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setHeightCm,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    label: '体重（kg）',
                    initialValue: state.weightKg,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setWeightKg,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    label: '腰围（cm）',
                    initialValue: state.waistCm,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setWaistCm,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    label: '疾病史（每行一项）',
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
                    label: Text(state.isSaving ? '保存中...' : '保存资料'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '提示：选择图片后将进入裁剪，并自动缩放为 1024x1024 后上传。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard({
    required BuildContext context,
    required ProfileState state,
    required VoidCallback onTapChangeAvatar,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  state.avatarBytes == null ? null : MemoryImage(state.avatarBytes!),
              child: state.avatarBytes == null
                  ? Icon(
                      Icons.person_outline,
                      size: 30,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('用户头像', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    state.isUploadingAvatar ? '上传中...' : '支持拍照或从相册选择，上传前会先裁剪',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: state.isUploadingAvatar ? null : onTapChangeAvatar,
              icon: state.isUploadingAvatar
                  ? const SizedBox.square(
                      dimension: 14,
                      child: FittedBox(child: CircularProgressIndicatorM3E()),
                    )
                  : const Icon(Icons.edit_outlined),
              label: const Text('更换'),
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
      decoration: const InputDecoration(labelText: '性别'),
      items: const [
        DropdownMenuItem(value: UserGender.unknown, child: Text('未知')),
        DropdownMenuItem(value: UserGender.male, child: Text('男')),
        DropdownMenuItem(value: UserGender.female, child: Text('女')),
        DropdownMenuItem(value: UserGender.other, child: Text('其他')),
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
                title: const Text('拍照'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('从相册选择'),
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
