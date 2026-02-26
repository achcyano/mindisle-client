import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/info/info_page.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_picker_sheet.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_selector.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_card.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';
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
            child: const Text('重试'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 5,
      children: [
        const SizedBox(height: 20),
        ProfileAvatarSelector(state: state, onTapChangeAvatar: null),
        const SizedBox(height: 3),
        Text(
          _displayName(state),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
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
                onTap: () => InfoPage.route.goRoot(context),
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
        SettingsGroup(
          children: [
            AppListTile(
              title: Text(_displayPhone(state)),
              subtitle: const Text('手机'),
              autoBorderRadius: true,
              position: AppListTilePosition.first,
              paddingTop: 8,
              paddingBottom: 8,
              onTap: (){
                // TODO 添加修改手机号ui
              },
            ),
            AppListTile(
              title: Text(_displayUserId(state)),
              subtitle: const Text('ID'),
              autoBorderRadius: true,
              position: AppListTilePosition.middle,
              paddingTop: 8,
              paddingBottom: 8,
              onTap: (){},
            ),
            AppListTile(
              title: Text(_displayBirthDate(state)),
              subtitle: const Text('生日'),
              autoBorderRadius: true,
              position: AppListTilePosition.last,
              paddingTop: 8,
              paddingBottom: 8,
              onTap: (){
                InfoPage.route.goRoot(context);
              },
            ),
          ],
        ),
      ],
    );
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

  String _displayName(ProfileState state) {
    final text = state.profile?.fullName?.trim() ?? '';
    if (text.isEmpty) return '未设置姓名';
    return text;
  }

  String _displayPhone(ProfileState state) {
    final text = state.phone.trim();
    if (text.isEmpty) return '未绑定手机号';
    return text;
  }

  String _displayUserId(ProfileState state) {
    final id = state.profile?.userId ?? 0;
    if (id <= 0) return '未获取';
    return id.toString();
  }

  String _displayBirthDate(ProfileState state) {
    final text =
        (state.birthDate.isNotEmpty
                ? state.birthDate
                : (state.profile?.birthDate ?? ''))
            .trim();
    if (text.isEmpty) return '未设置生日';
    return text;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
