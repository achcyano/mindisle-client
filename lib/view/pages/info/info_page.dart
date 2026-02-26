import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/app_dialog.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class InfoPage extends ConsumerStatefulWidget {
  const InfoPage({super.key});

  static final route = AppRoute<void>(
    path: '/info',
    builder: (_) => const InfoPage(),
  );

  @override
  ConsumerState<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends ConsumerState<InfoPage> {
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
      appBar: AppBar(title: const Text('编辑资料')),
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
        SettingsGroup(
          title: "个人信息",
          children: [
            AppListTile(
              title: Text(_displayPhone(state)),
              subtitle: const Text("手机号码"),
              leading: const Icon(Icons.phone_outlined),
              position: AppListTilePosition.middle,
              onTap: () {},
            ),
            AppListTile(
              title: Text(_displayBirthDate(state)),
              subtitle: const Text("出生日期"),
              leading: const Icon(Icons.cake_outlined),
              position: AppListTilePosition.last,
              onTap: state.isSaving
                  ? null
                  : () => _pickBirthDate(state: state, controller: controller),
            ),
          ],
        ),
        SettingsGroup(
            title: "您的姓名",
            children: [

            ]
        )
      ],
    );
  }

  String _displayPhone(ProfileState state) {
    final phone = state.phone.trim();
    if (phone.isEmpty) return '未绑定手机号';
    if (RegExp(r'^\d{11}$').hasMatch(phone)) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone
          .substring(7)}';
    }
    return phone;
  }

  String _displayBirthDate(ProfileState state) {
    final text =
    (state.birthDate.isNotEmpty
        ? state.birthDate
        : (state.profile?.birthDate ?? ''))
        .trim();
    if (text.isEmpty) return '未设置';

    final parsed = _tryParseBirthDate(text);
    if (parsed == null) return text;
    return '${parsed.year}年${parsed.month}月${parsed.day}日';
  }

  DateTime? _tryParseBirthDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  String _formatBirthDate(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _pickBirthDate({
    required ProfileState state,
    required ProfileController controller,
  }) async {
    final firstDate = DateTime(1900, 1, 1);
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    final initialCandidate = _tryParseBirthDate(
      state.birthDate
          .trim()
          .isNotEmpty
          ? state.birthDate.trim()
          : (state.profile?.birthDate ?? ''),
    );
    var initialDate = initialCandidate ?? DateTime(2000, 1, 1);
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showAppDialog<DateTime>(
      context: context,
      builder: (_) {
        return DatePickerDialog(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: '选择出生日期',
          cancelText: '取消',
          confirmText: '确定',
        );
      },
    );
    if (!mounted || picked == null) return;

    final selectedDate = DateTime(picked.year, picked.month, picked.day);
    final selectedValue = _formatBirthDate(selectedDate);
    final currentValue =
    state.birthDate
        .trim()
        .isNotEmpty
        ? state.birthDate.trim()
        : (state.profile?.birthDate ?? '').trim();
    if (selectedValue == currentValue) return;

    controller.setBirthDate(selectedValue);
    await _saveProfile(controller);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile(ProfileController controller) async {
    final message = await controller.saveProfile();
    if (!mounted || message == null || message.isEmpty) return;
    final errorMessage = ref
        .read(profileControllerProvider)
        .errorMessage;
    if (errorMessage != null && errorMessage == message) return;
    _showSnack(message);
  }
}
