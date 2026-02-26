import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/data/preference/const.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/home_shell.dart';
import 'package:mindisle_client/view/pages/info/info_disease_history_group.dart';
import 'package:mindisle_client/view/pages/info/info_field_label.dart';
import 'package:mindisle_client/view/pages/info/info_page_utils.dart';
import 'package:mindisle_client/view/pages/info/info_page_validation.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/app_dialog.dart';
import 'package:mindisle_client/view/widget/app_list_tile.dart';
import 'package:mindisle_client/view/widget/settings_card.dart';
import 'package:mindisle_client/view/widget/settings_input_field.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class InfoPage extends ConsumerStatefulWidget {
  const InfoPage({
    this.requireCompletion = false,
    super.key,
  });

  final bool requireCompletion;

  static final route = AppRoute<void>(
    path: '/info',
    builder: (_) => const InfoPage(),
  );

  static final requiredRoute = AppRoute<void>(
    path: '/info/required',
    builder: (_) => const InfoPage(requireCompletion: true),
  );

  @override
  ConsumerState<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends ConsumerState<InfoPage> {
  String? _lastErrorMessage;
  bool _allowPop = false;
  bool _isHandlingBack = false;

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
      if (message == null || message.isEmpty || message == _lastErrorMessage) {
        return;
      }
      _lastErrorMessage = message;
      _showSnack(message);
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return PopScope<void>(
      canPop: widget.requireCompletion ? false : _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.requireCompletion) {
          _showSnack('请先完成个人信息后继续');
          return;
        }
        _saveAndPop(controller);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.requireCompletion ? '完善个人信息' : '编辑资料'),
          automaticallyImplyLeading: !widget.requireCompletion,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: _buildContent(state: state, controller: controller),
          ),
        ),
        floatingActionButton: state.profile == null
            ? null
            : FloatingActionButton(
                onPressed: state.isSaving ? null : () => _saveAndPop(controller),
                child: const Icon(Icons.arrow_forward),
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
        _buildPersonalGroup(state, controller),
        _buildNameGroup(state, controller),
        _buildMetricGroup(state, controller),
        InfoDiseaseHistoryGroup(
          state: state,
          onDiseaseHistoryChanged: controller.setDiseaseHistoryInput,
          onShowSnack: _showSnack,
        ),
      ],
    );
  }

  Widget _buildPersonalGroup(ProfileState state, ProfileController controller) {
    return SettingsGroup(
      title: '个人信息',
      children: [
        AppListTile(
          title: Text(InfoPageUtils.displayPhone(state)),
          subtitle: const Text('手机号码'),
          leading: const Icon(Icons.phone_outlined),
          position: AppListTilePosition.first,
          onTap: null,
        ),
        AppListTile(
          title: Text(InfoPageUtils.displayGender(state.gender)),
          subtitle: const Text('性别'),
          leading: const Icon(Icons.wc_outlined),
          position: AppListTilePosition.middle,
          onTap: state.isSaving
              ? null
              : () => _pickGender(state: state, controller: controller),
        ),
        AppListTile(
          title: Text(InfoPageUtils.displayBirthDate(state)),
          subtitle: const Text('出生日期'),
          leading: const Icon(Icons.cake_outlined),
          position: AppListTilePosition.last,
          onTap: state.isSaving
              ? null
              : () => _pickBirthDate(state: state, controller: controller),
        ),
      ],
    );
  }

  Widget _buildNameGroup(ProfileState state, ProfileController controller) {
    return SettingsGroup(
      title: '您的姓名',
      children: [
        SettingsInputField(
          value: state.fullName,
          enabled: !state.isSaving,
          hintText: '请输入姓名',
          onChanged: controller.setFullName,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        ),
      ],
    );
  }

  Widget _buildMetricGroup(ProfileState state, ProfileController controller) {
    return SettingsGroup(
      children: [
        const InfoFieldLabel(text: '身高/cm'),
        SettingsInputField(
          value: state.heightCm,
          enabled: !state.isSaving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [InfoPageUtils.twoDecimalInputFormatter],
          onChanged: controller.setHeightCm,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        ),
        const Divider(height: 1, thickness: 0.2, indent: 16, endIndent: 16),
        const InfoFieldLabel(text: '体重/kg'),
        SettingsInputField(
          value: state.weightKg,
          enabled: !state.isSaving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [InfoPageUtils.twoDecimalInputFormatter],
          onChanged: controller.setWeightKg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        ),
        const Divider(height: 1, thickness: 0.2, indent: 16, endIndent: 16),
        const InfoFieldLabel(text: '腰围/cm'),
        SettingsInputField(
          value: state.waistCm,
          enabled: !state.isSaving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [InfoPageUtils.twoDecimalInputFormatter],
          onChanged: controller.setWaistCm,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        ),
      ],
    );
  }

  Future<void> _pickBirthDate({
    required ProfileState state,
    required ProfileController controller,
  }) async {
    final firstDate = DateTime(1900, 1, 1);
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    final initialCandidate = InfoPageUtils.tryParseBirthDate(
      InfoPageUtils.effectiveBirthDateText(state),
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
    final selectedValue = InfoPageUtils.formatBirthDate(selectedDate);
    final currentValue = InfoPageUtils.effectiveBirthDateText(state);
    if (selectedValue == currentValue) return;

    controller.setBirthDate(selectedValue);
  }

  Future<void> _pickGender({
    required ProfileState state,
    required ProfileController controller,
  }) async {
    final picked = await showAppDialog<UserGender>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return buildAppAlertDialog(
          title: const Text('选择性别'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final gender in UserGender.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(InfoPageUtils.displayGender(gender)),
                  trailing: gender == state.gender
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(dialogContext).pop(gender),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
    if (!mounted || picked == null || picked == state.gender) return;

    controller.setGender(picked);
  }

  Future<void> _saveAndPop(ProfileController controller) async {
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      final saved = await _saveBeforeExit(controller);
      if (!saved || !mounted) return;

      if (widget.requireCompletion) {
        await AppPrefs.hasCompletedFirstLogin.set(true);
        if (!mounted) return;
        await HomeShell.route.replaceRoot(context);
        return;
      }

      setState(() {
        _allowPop = true;
      });
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }

      setState(() {
        _allowPop = false;
      });
    } finally {
      if (mounted) {
        _isHandlingBack = false;
      }
    }
  }

  Future<bool> _saveBeforeExit(ProfileController controller) async {
    final validationMessage =
        validateInfoBeforeExit(ref.read(profileControllerProvider));
    if (validationMessage != null) {
      _showSnack(validationMessage);
      return false;
    }

    final message = await controller.saveProfile();
    if (!mounted || message == null || message.isEmpty) return false;

    final errorMessage = ref.read(profileControllerProvider).errorMessage;
    if (errorMessage != null && errorMessage == message) return false;

    _showSnack(message);
    return true;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
