import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_profile/domain/entities/doctor_profile_entities.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorThresholdsPage extends ConsumerStatefulWidget {
  const DoctorThresholdsPage({super.key});

  static final route = AppRoute<void>(
    path: '/me/thresholds',
    builder: (_) => const DoctorThresholdsPage(),
  );

  @override
  ConsumerState<DoctorThresholdsPage> createState() =>
      _DoctorThresholdsPageState();
}

class _DoctorThresholdsPageState extends ConsumerState<DoctorThresholdsPage> {
  bool _initialized = false;
  bool _isSaving = false;
  bool _allowPop = false;
  bool _isHandlingBack = false;

  String _initialPhq9 = '';
  String _initialGad7 = '';
  String _initialPsqi = '';
  String _initialScl90 = '';

  String _phq9 = '';
  String _gad7 = '';
  String _psqi = '';
  String _scl90 = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final thresholds = ref.read(doctorProfileControllerProvider).data.thresholds;
    _initialPhq9 = _asText(thresholds?.phq9Threshold);
    _initialGad7 = _asText(thresholds?.gad7Threshold);
    _initialPsqi = _asText(thresholds?.psqiThreshold);
    _initialScl90 = _asText(thresholds?.scl90Threshold);
    _phq9 = _initialPhq9;
    _gad7 = _initialGad7;
    _psqi = _initialPsqi;
    _scl90 = _initialScl90;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('阈值设置')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SettingsGroup(
                  title: '量表阈值',
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        '仅支持整数。留空表示不设置该量表阈值。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _ThresholdInputSection(
                      label: 'PHQ-9',
                      value: _phq9,
                      hintText: '例如 10',
                      isFirst: true,
                      onChanged: (value) => setState(() => _phq9 = value),
                    ),
                    _ThresholdInputSection(
                      label: 'GAD-7',
                      value: _gad7,
                      hintText: '例如 10',
                      onChanged: (value) => setState(() => _gad7 = value),
                    ),
                    _ThresholdInputSection(
                      label: 'PSQI',
                      value: _psqi,
                      hintText: '例如 7',
                      onChanged: (value) => setState(() => _psqi = value),
                    ),
                    _ThresholdInputSection(
                      label: 'SCL-90',
                      value: _scl90,
                      hintText: '例如 160',
                      isLast: true,
                      onChanged: (value) => setState(() => _scl90 = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
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

  String _asText(int? value) => value?.toString() ?? '';

  int? _parseNullableInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  bool _hasChanges() {
    return _phq9.trim() != _initialPhq9 ||
        _gad7.trim() != _initialGad7 ||
        _psqi.trim() != _initialPsqi ||
        _scl90.trim() != _initialScl90;
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

    if (!_hasChanges()) {
      return true;
    }

    setState(() {
      _isSaving = true;
    });

    final message = await ref
        .read(doctorProfileControllerProvider.notifier)
        .updateThresholds(
          DoctorThresholds(
            phq9Threshold: _parseNullableInt(_phq9),
            gad7Threshold: _parseNullableInt(_gad7),
            psqiThreshold: _parseNullableInt(_psqi),
            scl90Threshold: _parseNullableInt(_scl90),
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

    _initialPhq9 = _phq9.trim();
    _initialGad7 = _gad7.trim();
    _initialPsqi = _psqi.trim();
    _initialScl90 = _scl90.trim();
    showAuthSnackBar(context, '阈值保存成功', useCustomKeypad: false);
    return true;
  }
}

class _ThresholdInputSection extends StatelessWidget {
  const _ThresholdInputSection({
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
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          padding: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 6 : 0),
        ),
      ],
    );
  }
}
