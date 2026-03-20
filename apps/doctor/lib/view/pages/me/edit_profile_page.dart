import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_controller.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorEditProfilePage extends ConsumerStatefulWidget {
  const DoctorEditProfilePage({super.key});

  static final route = AppRoute<void>(
    path: '/me/profile',
    builder: (_) => const DoctorEditProfilePage(),
  );

  @override
  ConsumerState<DoctorEditProfilePage> createState() =>
      _DoctorEditProfilePageState();
}

class _DoctorEditProfilePageState extends ConsumerState<DoctorEditProfilePage> {
  bool _initialized = false;
  bool _isSaving = false;
  bool _allowPop = false;
  bool _isHandlingBack = false;

  String _initialFullName = '';
  String _initialHospital = '';
  String _fullName = '';
  String _hospital = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(doctorProfileControllerProvider);
      if (state.data.profile == null && !state.isLoading) {
        ref.read(doctorProfileControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorProfileControllerProvider);
    final controller = ref.read(doctorProfileControllerProvider.notifier);
    final profile = state.data.profile;

    if (!_initialized && profile != null) {
      _initializeWithProfile(profile);
    }

    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('编辑资料')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: _buildContent(
              state: state,
              controller: controller,
              profile: profile,
            ),
          ),
        ),
        floatingActionButton: profile == null
            ? null
            : FloatingActionButton(
                onPressed: _isSaving ? null : _saveAndPop,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
              ),
      ),
    );
  }

  Widget _buildContent({
    required DoctorProfileState state,
    required DoctorProfileController controller,
    required DoctorProfile? profile,
  }) {
    if (state.isLoading && profile == null) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicatorM3E()),
      );
    }

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
        SettingsGroup(
          title: '个人资料',
          children: [
            _ProfileInputSection(
              label: '姓名',
              value: _fullName,
              hintText: '请输入姓名',
              isFirst: true,
              onChanged: (value) => setState(() => _fullName = value),
            ),
            _ProfileInputSection(
              label: '医院',
              value: _hospital,
              hintText: '请输入医院',
              isLast: true,
              onChanged: (value) => setState(() => _hospital = value),
            ),
          ],
        ),
      ],
    );
  }

  void _initializeWithProfile(DoctorProfile profile) {
    _initialized = true;
    _initialFullName = profile.fullName.trim();
    _initialHospital = profile.hospital?.trim() ?? '';
    _fullName = _initialFullName;
    _hospital = _initialHospital;
  }

  bool _hasChanges() {
    return _fullName.trim() != _initialFullName ||
        _hospital.trim() != _initialHospital;
  }

  String? _validate() {
    if (_fullName.trim().isEmpty) return '请输入姓名';
    if (_hospital.trim().isEmpty) return '请输入医院';
    return null;
  }

  Future<void> _saveAndPop() async {
    if (_isHandlingBack || _isSaving) return;
    _isHandlingBack = true;
    try {
      final saved = await _saveBeforeExit();
      if (!saved || !mounted) return;

      setState(() {
        _allowPop = true;
      });
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        _isHandlingBack = false;
      }
    }
  }

  Future<bool> _saveBeforeExit() async {
    FocusScope.of(context).unfocus();

    final validationMessage = _validate();
    if (validationMessage != null) {
      showAuthSnackBar(context, validationMessage, useCustomKeypad: false);
      return false;
    }

    if (!_hasChanges()) {
      return true;
    }

    setState(() {
      _isSaving = true;
    });

    final message = await ref
        .read(doctorProfileControllerProvider.notifier)
        .updateProfile(
          DoctorProfileUpdatePayload(
            fullName: _fullName.trim(),
            hospital: _hospital.trim(),
          ),
        );

    if (!mounted) return false;

    setState(() {
      _isSaving = false;
    });

    if (message != null && message.isNotEmpty) {
      showAuthSnackBar(context, message, useCustomKeypad: false);
      return false;
    }

    _initialFullName = _fullName.trim();
    _initialHospital = _hospital.trim();
    showAuthSnackBar(context, '个人资料保存成功', useCustomKeypad: false);
    return true;
  }
}

class _ProfileInputSection extends StatelessWidget {
  const _ProfileInputSection({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hintText,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst)
          const Divider(height: 1, thickness: 0.2, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(label, style: labelStyle),
        ),
        SettingsInputField(
          value: value,
          onChanged: onChanged,
          hintText: hintText,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          padding: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 6 : 0),
        ),
      ],
    );
  }
}
