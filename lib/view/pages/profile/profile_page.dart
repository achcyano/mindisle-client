import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_picker_sheet.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_selector.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_basic_info_form_card.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_card.dart';
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
      _showSnack(message);
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: _buildContent(state: state, controller: controller),
        ),
      ),
    );
  }

  Widget _buildContent({
    required ProfileState state,
    required ProfileController controller,
  }) {
    if (state.isLoading && state.profile == null) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicatorM3E()),
      );
    }

    if (state.profile == null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: FilledButton(
            onPressed: () => controller.initialize(refresh: true),
            child: const Text('Retry'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 25),
        ProfileAvatarSelector(state: state, onTapChangeAvatar: null),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ProfileCard(
                icon: Icons.add_a_photo_outlined,
                title: '设置照片',
                onTap: state.isUploadingAvatar ? null : _showAvatarPickerSheet,
              ),
            ),
            Expanded(
              child: ProfileCard(
                icon: Icons.edit_outlined,
                title: '编辑信息',
                onTap: null,
              ),
            ),
            Expanded(
              child: ProfileCard(
                icon: Icons.person_add_alt,
                title: '我的医生',
                onTap: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProfileBasicInfoFormCard(
          data: ProfileBasicInfoFormData.fromState(state),
          actions: ProfileBasicInfoFormActions.fromController(
            controller: controller,
            onSavePressed: state.isSaving
                ? null
                : () => _saveProfile(controller),
          ),
        ),
      ],
    );
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile(ProfileController controller) async {
    final message = await controller.saveProfile();
    if (!mounted || message == null || message.isEmpty) return;
    _showSnack(message);
  }

  Future<void> _showAvatarPickerSheet() async {
    final source = await showProfileAvatarPickerSheet(context);
    if (!mounted || source == null) return;

    final message = await ref
        .read(profileControllerProvider.notifier)
        .pickAndUploadAvatar(source);
    if (!mounted || message == null || message.isEmpty) return;
    _showSnack(message);
  }
}
