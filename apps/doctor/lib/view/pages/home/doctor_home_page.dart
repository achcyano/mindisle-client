import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:doctor/features/doctor_auth/presentation/auth/doctor_auth_controller.dart';
import 'package:doctor/features/doctor_binding/presentation/binding/doctor_binding_controller.dart';
import 'package:doctor/features/doctor_medication/presentation/medication/doctor_medication_controller.dart';
import 'package:doctor/features/doctor_monitor/presentation/monitor/doctor_monitor_controller.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_controller.dart';
import 'package:doctor/features/doctor_profile/presentation/profile/doctor_profile_controller.dart';
import 'package:doctor/features/doctor_scale/presentation/scale/doctor_scale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

class DoctorHomePage extends ConsumerStatefulWidget {
  const DoctorHomePage({super.key});

  @override
  ConsumerState<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends ConsumerState<DoctorHomePage> {
  final TextEditingController _patientIdController = TextEditingController(
    text: '1',
  );

  int get _patientUserId => int.tryParse(_patientIdController.text.trim()) ?? 1;

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(doctorAuthControllerProvider);
    final profileState = ref.watch(doctorProfileControllerProvider);
    final bindingState = ref.watch(doctorBindingControllerProvider);
    final patientState = ref.watch(doctorPatientControllerProvider);
    final scaleState = ref.watch(doctorScaleControllerProvider);
    final medicationState = ref.watch(doctorMedicationControllerProvider);
    final monitorState = ref.watch(doctorMonitorControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('医生端工作台')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('患者 ID（用于患者相关接口）'),
                  const SizedBox(height: 8),
                  TextField(controller: _patientIdController),
                ],
              ),
            ),
          ),
          _SectionCard(
            title: '认证',
            subtitle: authState.lastSession == null
                ? '未登录'
                : 'doctorId=${authState.lastSession!.doctorId}',
            errorMessage: authState.errorMessage,
            loading: authState.isLoading,
            actions: [
              FilledButton(
                onPressed: () async {
                  final msg = await ref
                      .read(doctorAuthControllerProvider.notifier)
                      .sendSmsCode(
                        phone: '13800138000',
                        purpose: DoctorSmsPurpose.register,
                      );
                  if (!mounted || msg == null) return;
                  _showSnack(msg);
                },
                child: const Text('发送验证码'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  final msg = await ref
                      .read(doctorAuthControllerProvider.notifier)
                      .loginPassword(phone: '13800138000', password: '123456');
                  if (!mounted || msg == null) return;
                  _showSnack(msg);
                },
                child: const Text('密码登录'),
              ),
            ],
          ),
          _SectionCard(
            title: '医生资料与阈值',
            subtitle: 'profile=${profileState.profile?.fullName ?? '-'}',
            errorMessage: profileState.errorMessage,
            loading: profileState.isLoading,
            actions: [
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(doctorProfileControllerProvider.notifier).refresh(),
                child: const Text('刷新'),
              ),
            ],
          ),
          _SectionCard(
            title: '绑定码与绑定历史',
            subtitle: 'history=${bindingState.history.length}',
            errorMessage: bindingState.errorMessage,
            loading: bindingState.isLoading,
            actions: [
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(doctorBindingControllerProvider.notifier).createCode(),
                child: const Text('生成绑定码'),
              ),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorBindingControllerProvider.notifier)
                    .refreshHistory(),
                child: const Text('刷新历史'),
              ),
            ],
          ),
          _SectionCard(
            title: '患者管理',
            subtitle: 'patients=${patientState.items.length}',
            errorMessage: patientState.errorMessage,
            loading: patientState.isLoading,
            actions: [
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(doctorPatientControllerProvider.notifier).refresh(),
                child: const Text('刷新患者列表'),
              ),
            ],
          ),
          _SectionCard(
            title: '量表分析',
            subtitle: 'trends=${scaleState.trends.length}',
            errorMessage: scaleState.errorMessage,
            loading: scaleState.isLoading,
            actions: [
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorScaleControllerProvider.notifier)
                    .loadTrends(patientUserId: _patientUserId),
                child: const Text('加载趋势'),
              ),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorScaleControllerProvider.notifier)
                    .generateReport(patientUserId: _patientUserId),
                child: const Text('生成报告'),
              ),
            ],
          ),
          _SectionCard(
            title: '代管用药',
            subtitle: 'items=${medicationState.items.length}',
            errorMessage: medicationState.errorMessage,
            loading: medicationState.isLoading,
            actions: [
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorMedicationControllerProvider.notifier)
                    .refresh(patientUserId: _patientUserId),
                child: const Text('刷新用药'),
              ),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorMedicationControllerProvider.notifier)
                    .create(
                      patientUserId: _patientUserId,
                      payload: const UpsertMedicationPayload(
                        drugName: '示例药品',
                        doseTimes: <String>['21:00'],
                        endDate: '2099-12-31',
                        doseAmount: 1,
                        doseUnit: MedicationDoseUnit.tablet,
                        tabletStrengthAmount: 2,
                        tabletStrengthUnit: MedicationStrengthUnit.mg,
                      ),
                    ),
                child: const Text('新建示例用药'),
              ),
            ],
          ),
          _SectionCard(
            title: '观察指标汇总',
            subtitle:
                'summary=${monitorState.summary.length}, weight=${monitorState.weightTrend.length}',
            errorMessage: monitorState.errorMessage,
            loading: monitorState.isLoading,
            actions: [
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorMonitorControllerProvider.notifier)
                    .refresh(patientUserId: _patientUserId),
                child: const Text('刷新指标'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (message.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.actions,
    this.loading = false,
    this.errorMessage,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
            if (loading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
