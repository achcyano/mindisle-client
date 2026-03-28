import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:patient/features/event/domain/entities/event_entities.dart';
import 'package:patient/features/event/presentation/binding/patient_doctor_binding_controller.dart';
import 'package:patient/features/event/presentation/binding/patient_doctor_binding_state.dart';

class PatientDoctorBindingPage extends ConsumerStatefulWidget {
  const PatientDoctorBindingPage({super.key});

  static final route = AppRoute<bool>(
    path: '/home/doctor-binding',
    builder: (_) => const PatientDoctorBindingPage(),
  );

  @override
  ConsumerState<PatientDoctorBindingPage> createState() =>
      _PatientDoctorBindingPageState();
}

class _PatientDoctorBindingPageState
    extends ConsumerState<PatientDoctorBindingPage> {
  late final MobileScannerController _scannerController =
      MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
      );
  bool _hasChanged = false;
  String? _lastErrorMessage;
  DateTime? _lastInvalidScanAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(patientDoctorBindingControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PatientDoctorBindingState>(
      patientDoctorBindingControllerProvider,
      (previous, next) {
        final message = next.errorMessage?.trim() ?? '';
        if (message.isEmpty || message == _lastErrorMessage) return;
        _lastErrorMessage = message;
        _showSnack(message);
      },
    );

    final state = ref.watch(patientDoctorBindingControllerProvider);

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closePage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('绑定医生'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closePage,
          ),
          actions: [
            IconButton(
              tooltip: '刷新状态',
              onPressed: state.isLoading
                  ? null
                  : () => ref
                        .read(patientDoctorBindingControllerProvider.notifier)
                        .refreshStatus(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(patientDoctorBindingControllerProvider.notifier)
                .refreshStatus(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: _buildContent(state, constraints.maxHeight),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PatientDoctorBindingState state, double viewportHeight) {
    if (state.isLoading && state.status == null) {
      return const Center(child: CircularProgressIndicatorM3E());
    }

    if (state.status == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: RetryErrorCard(
          title: '获取绑定状态失败',
          message: (state.errorMessage?.trim().isNotEmpty ?? false)
              ? state.errorMessage!.trim()
              : '请下拉刷新重试',
          onRetry: () => ref
              .read(patientDoctorBindingControllerProvider.notifier)
              .refreshStatus(),
          isRetrying: state.isLoading,
        ),
      );
    }

    if (state.isBound) {
      return _BoundDoctorSection(status: state.status!);
    }

    return _UnboundDoctorSection(
      state: state,
      viewportHeight: viewportHeight,
      scannerController: _scannerController,
      onModeChanged: (mode) => ref
          .read(patientDoctorBindingControllerProvider.notifier)
          .setMode(mode),
      onDigitPressed: (digit) => ref
          .read(patientDoctorBindingControllerProvider.notifier)
          .inputDigit(digit),
      onBackspacePressed: () => ref
          .read(patientDoctorBindingControllerProvider.notifier)
          .deleteDigit(),
      onSubmitManual: _submitManualBinding,
      onDetectScan: _handleScanCapture,
    );
  }

  Future<void> _submitManualBinding() async {
    final wasBound = ref.read(patientDoctorBindingControllerProvider).isBound;
    final message = await ref
        .read(patientDoctorBindingControllerProvider.notifier)
        .submitInputCode();
    if (!mounted || message == null || message.isEmpty) return;

    _showSnack(message);
    final isBoundNow = ref.read(patientDoctorBindingControllerProvider).isBound;
    if (!wasBound && isBoundNow) {
      _hasChanged = true;
    }
  }

  Future<void> _handleScanCapture(BarcodeCapture capture) async {
    final state = ref.read(patientDoctorBindingControllerProvider);
    if (state.mode != PatientDoctorBindingMode.scan || state.isBusy) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim() ?? '';
      if (raw.isEmpty) continue;

      final wasBound = state.isBound;
      final message = await ref
          .read(patientDoctorBindingControllerProvider.notifier)
          .submitScannedPayload(raw);
      if (!mounted || message == null || message.isEmpty) return;

      if (message == '二维码中未识别到有效的 5 位绑定码') {
        final now = DateTime.now();
        if (_lastInvalidScanAt != null &&
            now.difference(_lastInvalidScanAt!) < const Duration(seconds: 2)) {
          return;
        }
        _lastInvalidScanAt = now;
      }

      _showSnack(message);
      final isBoundNow = ref
          .read(patientDoctorBindingControllerProvider)
          .isBound;
      if (!wasBound && isBoundNow) {
        _hasChanged = true;
      }
      return;
    }
  }

  void _closePage() {
    Navigator.of(context).pop(_hasChanged);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BoundDoctorSection extends StatelessWidget {
  const _BoundDoctorSection({required this.status});

  final DoctorBindingStatus status;

  @override
  Widget build(BuildContext context) {
    final doctorName = (status.currentDoctorName ?? '').trim();
    final displayName = doctorName.isEmpty ? '医生信息待完善' : doctorName;
    final doctorHospital = (status.currentDoctorHospital ?? '').trim();
    final subtitle = doctorHospital.isEmpty ? '医院信息待完善' : doctorHospital;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已绑定医生', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.health_and_safety_outlined),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '请联系医生解除绑定',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _UnboundDoctorSection extends StatelessWidget {
  const _UnboundDoctorSection({
    required this.state,
    required this.viewportHeight,
    required this.scannerController,
    required this.onModeChanged,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmitManual,
    required this.onDetectScan,
  });

  final PatientDoctorBindingState state;
  final double viewportHeight;
  final MobileScannerController scannerController;
  final ValueChanged<PatientDoctorBindingMode> onModeChanged;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmitManual;
  final Future<void> Function(BarcodeCapture capture) onDetectScan;

  @override
  Widget build(BuildContext context) {
    final modeSwitcher = SegmentedButton<PatientDoctorBindingMode>(
      selected: <PatientDoctorBindingMode>{state.mode},
      onSelectionChanged: state.isBusy
          ? null
          : (selection) {
              if (selection.isEmpty) return;
              onModeChanged(selection.first);
            },
      segments: const [
        ButtonSegment<PatientDoctorBindingMode>(
          value: PatientDoctorBindingMode.manual,
          icon: Icon(Icons.dialpad_outlined),
          label: Text('输入绑定码'),
        ),
        ButtonSegment<PatientDoctorBindingMode>(
          value: PatientDoctorBindingMode.scan,
          icon: Icon(Icons.qr_code_scanner),
          label: Text('扫码绑定'),
        ),
      ],
    );

    if (state.mode == PatientDoctorBindingMode.manual) {
      return SizedBox(
        height: viewportHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            modeSwitcher,
            const SizedBox(height: 12),
            Expanded(
              child: AuthOtpStepView(
                phoneDigits: '',
                otpDigits: state.inputCode,
                inlineError: state.errorMessage,
                isSubmitting: state.isSubmitting,
                title: '输入绑定码',
                descriptionBuilder: (_) => '请输入医生提供的 5 位绑定码',
                showSubmitButton: true,
                autoSubmitOnComplete: true,
                codeLength: 5,
                onDigitPressed: onDigitPressed,
                onBackspacePressed: onBackspacePressed,
                onSubmit: onSubmitManual,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        modeSwitcher,
        const SizedBox(height: 12),
        _ScanBindingPanel(
          scannerController: scannerController,
          onDetect: onDetectScan,
          enabled: !state.isBusy,
        ),
      ],
    );
  }
}

class _ScanBindingPanel extends StatelessWidget {
  const _ScanBindingPanel({
    required this.scannerController,
    required this.onDetect,
    required this.enabled,
  });

  final MobileScannerController scannerController;
  final Future<void> Function(BarcodeCapture capture) onDetect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: enabled ? 1 : 0.55,
                      child: MobileScanner(
                        controller: scannerController,
                        onDetect: onDetect,
                      ),
                    ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: borderColor.withValues(alpha: 0.85),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '将医生端绑定二维码放入框内自动识别',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
