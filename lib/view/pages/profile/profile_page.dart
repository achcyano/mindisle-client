import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_picker_sheet.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_selector.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_basic_info_form_card.dart';
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
                ProfileAvatarSelector(
                  state: state,
                  onTapChangeAvatar: _showAvatarPickerSheet,
                ),
                const SizedBox(height: 16),
                ProfileBasicInfoFormCard(
                  formIdentity: _buildFormIdentity(state),
                  state: state,
                  onFullNameChanged: controller.setFullName,
                  onGenderChanged: controller.setGender,
                  onBirthDateChanged: controller.setBirthDate,
                  onHeightChanged: controller.setHeightCm,
                  onWeightChanged: controller.setWeightKg,
                  onWaistChanged: controller.setWaistCm,
                  onDiseaseHistoryChanged: controller.setDiseaseHistoryInput,
                  onSavePressed:
                      state.isSaving ? null : () => _saveProfile(controller),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildFormIdentity(ProfileState state) {
    final profile = state.profile!;
    return [
      profile.userId,
      profile.fullName ?? '',
      profile.gender.name,
      profile.birthDate ?? '',
      profile.heightCm?.toString() ?? '',
      profile.weightKg?.toString() ?? '',
      profile.waistCm?.toString() ?? '',
      profile.diseaseHistory.join('|'),
    ].join('#');
  }

  Future<void> _saveProfile(ProfileController controller) async {
    final message = await controller.saveProfile();
    if (!mounted || message == null || message.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAvatarPickerSheet() async {
    final source = await showProfileAvatarPickerSheet(context);
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
