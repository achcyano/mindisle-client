import 'dart:io';

import 'package:app_core/app_core.dart';
import 'package:app_ui/app_ui.dart';
import 'package:doctor/core/providers/app_providers.dart';
import 'package:doctor/core/static.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_controller.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/presentation/providers/doctor_patient_providers.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_controller.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_state.dart';
import 'package:doctor/view/pages/auth/login_page.dart';
import 'package:doctor/view/pages/auth/reset_password_page.dart';
import 'package:doctor/view/pages/me/edit_profile_page.dart';
import 'package:doctor/view/pages/me/thresholds_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DoctorMePage extends ConsumerStatefulWidget {
  const DoctorMePage({super.key, this.writeExportFile, this.shareExportFile});

  final Future<File> Function(DoctorPatientExportFile file)? writeExportFile;
  final Future<void> Function(File file, DoctorPatientExportFile meta)?
  shareExportFile;

  static final route = AppRoute<void>(
    path: '/me',
    builder: (_) => const DoctorMePage(),
  );

  @override
  ConsumerState<DoctorMePage> createState() => _DoctorMePageState();
}

class _DoctorMePageState extends ConsumerState<DoctorMePage> {
  String? _lastErrorMessage;
  bool _isLoggingOut = false;
  bool _isExportingPatients = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(doctorProfileControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DoctorProfileState>(doctorProfileControllerProvider, (
      previous,
      next,
    ) {
      final message = next.errorMessage?.trim() ?? '';
      if (message.isEmpty || message == _lastErrorMessage) return;
      _lastErrorMessage = message;
      _showSnack(message);
    });

    final state = ref.watch(doctorProfileControllerProvider);
    final controller = ref.read(doctorProfileControllerProvider.notifier);

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
    required DoctorProfileState state,
    required DoctorProfileController controller,
  }) {
    if (state.isLoading && state.data.profile == null) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicatorM3E()),
      );
    }

    final profile = state.data.profile;
    if (profile == null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: FilledButton(
            onPressed: controller.refresh,
            child: const Text('重试'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfileHeroSection(
          avatar: _DoctorAvatar(isLoading: state.isLoading),
          title: _displayName(profile),
          subtitle: _displayHospital(profile),
          actions: [
            ProfileActionCard(
              icon: Icons.edit_outlined,
              title: '编辑资料',
              onTap: () => DoctorEditProfilePage.route.go(context),
            ),
            ProfileActionCard(
              icon: Icons.tune,
              title: '阈值设置',
              onTap: () => DoctorThresholdsPage.route.go(context),
            ),
            ProfileActionCard(
              icon: Icons.info_outline,
              title: '关于心岛',
              onTap: _showAboutAppDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SettingsGroup(
          children: [
            AppListTile(
              title: Text(_displayPhone(profile)),
              subtitle: const Text('手机'),
              position: AppListTilePosition.first,
            ),
            AppListTile(
              title: Text(_displayDoctorId(profile)),
              subtitle: const Text('医生 ID'),
              position: AppListTilePosition.middle,
            ),
            AppListTile(
              title: Text(_displayHospital(profile)),
              subtitle: const Text('医院'),
              position: AppListTilePosition.last,
              onTap: () => DoctorEditProfilePage.route.go(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SettingsGroup(
          children: [
            AppListTile(
              title: const Text('导出患者数据'),
              position: AppListTilePosition.first,
              leadingIcon: Icons.download_outlined,
              trailing: _isExportingPatients
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: FittedBox(child: CircularProgressIndicatorM3E()),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isExportingPatients ? null : _exportPatients,
            ),
            AppListTile(
              title: const Text('修改密码'),
              position: AppListTilePosition.middle,
              leading: Icon(
                Icons.lock_reset_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => _confirmOpenResetPassword(profile),
            ),
            AppListTile(
              title: const Text('退出登录'),
              position: AppListTilePosition.last,
              leading: Icon(
                Icons.logout_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: _isLoggingOut ? null : _confirmLogout,
            ),
          ],
        ),
      ],
    );
  }

  String _displayName(DoctorProfile profile) {
    final value = profile.fullName.trim();
    return value.isEmpty ? '未设置姓名' : value;
  }

  String _displayPhone(DoctorProfile profile) {
    final value = profile.phone.trim();
    return value.isEmpty ? '未绑定手机号' : value;
  }

  String _displayDoctorId(DoctorProfile profile) {
    if (profile.doctorId <= 0) return '未获取';
    return profile.doctorId.toString();
  }

  String _displayHospital(DoctorProfile profile) {
    final value = profile.hospital?.trim() ?? '';
    return value.isEmpty ? '未设置医院' : value;
  }

  Future<void> _openResetPassword(DoctorProfile profile) async {
    final phone = profile.phone.trim();
    if (phone.isEmpty) {
      _showSnack('未绑定手机号，暂时无法修改密码');
      return;
    }

    await DoctorResetPasswordPage.route.goRoot(context, phone);
  }

  Future<void> _confirmOpenResetPassword(DoctorProfile profile) async {
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
    await _openResetPassword(profile);
  }

  Future<void> _showAboutAppDialog() async {
    if (!mounted) return;

    showAboutDialog(
      context: context,
      applicationName: appDisplayName,
      applicationIcon: Image.asset(
        'assets/icon/app_icon_foreground.png',
        width: 64,
        height: 64,
      ),
    );
  }

  Future<void> _exportPatients() async {
    if (_isExportingPatients) return;
    setState(() {
      _isExportingPatients = true;
    });

    try {
      final result = await ref
          .read(exportDoctorPatientsUseCaseProvider)
          .execute();
      if (!mounted) return;

      switch (result) {
        case Success<DoctorPatientExportFile>(data: final file):
          if (file.bytes.isEmpty) {
            _showSnack('导出失败，文件内容为空');
            return;
          }
          final outputFile = await _writeExportFile(file);
          if (!mounted) return;
          setState(() {
            _isExportingPatients = false;
          });
          final shouldShare = await _showExportSuccessDialog(file.fileName);
          if (shouldShare != true || !mounted) return;
          await _shareExportFile(file: outputFile, meta: file);
          return;
        case Failure<DoctorPatientExportFile>(error: final error):
          _showSnack(error.message);
          return;
      }
    } on FileSystemException catch (_) {
      _showSnack('导出失败，文件写入异常，请稍后重试');
    } catch (_) {
      _showSnack('导出失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPatients = false;
        });
      }
    }
  }

  Future<Directory> _resolveExportDirectory() async {
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<File> _writeExportFile(DoctorPatientExportFile file) async {
    if (widget.writeExportFile case final customWriter?) {
      return customWriter(file);
    }

    final directory = await _resolveExportDirectory();
    final outputPath =
        '${directory.path}${Platform.pathSeparator}${file.fileName}';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(file.bytes, flush: true);
    return outputFile;
  }

  Future<bool?> _showExportSuccessDialog(String fileName) {
    return showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return buildAppAlertDialog(
          title: const Text('导出成功'),
          content: Text('文件已下载：$fileName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('稍后'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('分享文件'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareExportFile({
    required File file,
    required DoctorPatientExportFile meta,
  }) async {
    try {
      if (widget.shareExportFile case final customShare?) {
        await customShare(file, meta);
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path, mimeType: meta.mimeType, name: meta.fileName),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('分享失败，请稍后重试');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        return buildAppAlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定退出登录吗？'),
          actions: <Widget>[
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
      final refreshToken = await ref
          .read(sessionStoreProvider)
          .readRefreshToken();
      final result = await ref
          .read(doctorLogoutUseCaseProvider)
          .execute(refreshToken: refreshToken);
      if (!mounted) return;

      switch (result) {
        case Success<void>():
          await ref.read(sessionStoreProvider).clearSession();
          if (!mounted) return;
          ref.read(doctorAuthControllerProvider.notifier).clearSession();
          await DoctorLoginPage.route.replaceRoot(context);
          return;
        case Failure<void>(error: final error):
          if (error.type == AppErrorType.unauthorized) {
            await ref.read(sessionStoreProvider).clearSession();
            if (!mounted) return;
            ref.read(doctorAuthControllerProvider.notifier).clearSession();
            await DoctorLoginPage.route.replaceRoot(context);
            return;
          }
          _showSnack(error.message);
          return;
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

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.medical_services_outlined,
              size: 42,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          if (isLoading)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              child: const Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicatorM3E(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
