import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/providers/app_providers.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/features/auth/presentation/providers/auth_providers.dart';
import 'package:mindisle_client/features/user/presentation/providers/user_providers.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/info/info_page.dart';
import 'package:mindisle_client/view/pages/login/login_page.dart';
import 'package:mindisle_client/view/pages/login/reset_password_page.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_picker_sheet.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_avatar_selector.dart';
import 'package:mindisle_client/view/pages/profile/widgets/profile_card.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/app_dialog.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoggingOut = false;

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
                title: '设置头像',
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
              position: AppListTilePosition.first,
              onTap: () {},
            ),
            AppListTile(
              title: Text(_displayUserId(state)),
              subtitle: const Text('ID'),
              position: AppListTilePosition.middle,
              onTap: () {},
            ),
            AppListTile(
              title: Text(_displayBirthDate(state)),
              subtitle: const Text('生日'),
              position: AppListTilePosition.last,
              onTap: () {
                InfoPage.route.goRoot(context);
              },
            ),
          ],
        ),
        SettingsGroup(
          children: [
            AppListTile(
              title: const Text('退出登录'),
              position: AppListTilePosition.first,
              leading: Icon(
                Icons.logout_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: _isLoggingOut ? null : _confirmLogout,
            ),
            AppListTile(
              title: const Text('修改密码'),
              position: AppListTilePosition.last,
              leading: Icon(
                Icons.edit_note,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => _confirmOpenResetPassword(state),
            ),
          ],
        ),
        SettingsGroup(
          children: [
            AppListTile(
              title: const Text('关于心岛'),
              position: AppListTilePosition.single,
              leading: const Icon(Icons.info_outlined),
              onTap: _showAboutAppDialog,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAboutAppDialog() async {
    final info = await _loadPackageInfoSafely();
    if (!mounted) return;

    final versionText = info == null
        ? '版本信息暂不可用'
        : '${info.version} (${info.buildNumber})';

    showAboutDialog(
      context: context,
      applicationName: '心岛',
      applicationVersion: versionText,
      applicationIcon: Image.asset(
        'assets/icon/app_icon_foreground.png',
        width: 64,
        height: 64,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () async {
              if (!await launchUrl(
                Uri.parse(homeUrl),
                mode: LaunchMode.externalApplication,
              )) {
                if (mounted) {
                  _showSnack('无法打开网页');
                }
              }
            },
            child: const Text('GitHub'),
          ),
        ),
      ],
    );
  }

  Future<PackageInfo?> _loadPackageInfoSafely() async {
    try {
      return await PackageInfo.fromPlatform();
    } on MissingPluginException {
      if (mounted) {
        _showSnack('版本信息暂不可用，请重启应用后再试');
      }
      return null;
    } on PlatformException {
      if (mounted) {
        _showSnack('版本信息获取失败，请稍后重试');
      }
      return null;
    }
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

  Future<void> _openResetPassword(ProfileState state) async {
    var phone = state.phone.trim();
    if (phone.isEmpty) {
      final meResult = await ref.read(getMeUseCaseProvider).execute();
      switch (meResult) {
        case Success(data: final me):
          phone = me.phone.trim();
        case Failure(error: final error):
          final message = error.message.trim();
          _showSnack(message.isEmpty ? '无法获取手机号，请稍后重试' : message);
          return;
      }
    }

    if (phone.isEmpty) {
      _showSnack('未绑定手机号，暂无法修改密码');
      return;
    }

    if (!mounted) return;
    await ResetPasswordPage.route.goRoot(context, phone);
  }

  Future<void> _confirmOpenResetPassword(ProfileState state) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        return buildAppAlertDialog(
          title: const Text('修改密码'),
          content: const Text('将通过短信验证码验证身份后重置密码，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: errorColor),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await _openResetPassword(state);
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        return buildAppAlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: errorColor),
              child: const Text('退出登录'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _logout();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final refreshToken = await ref.read(sessionStoreProvider).readRefreshToken();
      final result = await ref
          .read(logoutUseCaseProvider)
          .execute(refreshToken: refreshToken);
      if (!mounted) return;

      switch (result) {
        case Success<void>():
          await LoginPage.route.replaceRoot(context);
        case Failure<void>(error: final error):
          final message = error.message.trim();
          _showSnack(message.isEmpty ? '退出登录失败，请稍后重试' : message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
