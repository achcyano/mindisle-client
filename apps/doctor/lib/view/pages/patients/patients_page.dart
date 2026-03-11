import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_medication/presentation/medication/doctor_medication_controller.dart';
import 'package:doctor/features/doctor_monitor/presentation/monitor/doctor_monitor_controller.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_controller.dart';
import 'package:doctor/features/doctor_scale/presentation/scale/doctor_scale_controller.dart';
import 'package:doctor/view/pages/home/widgets/doctor_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

class DoctorPatientsPage extends ConsumerStatefulWidget {
  const DoctorPatientsPage({super.key});

  static final route = AppRoute<void>(
    path: '/patients',
    builder: (_) => const DoctorPatientsPage(),
  );

  @override
  ConsumerState<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends ConsumerState<DoctorPatientsPage> {
  final TextEditingController _patientIdController = TextEditingController(
    text: '1',
  );

  int get _patientUserId => int.tryParse(_patientIdController.text.trim()) ?? 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorPatientControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(doctorPatientControllerProvider);
    final scaleState = ref.watch(doctorScaleControllerProvider);
    final medicationState = ref.watch(doctorMedicationControllerProvider);
    final monitorState = ref.watch(doctorMonitorControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('患者')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SettingsGroup(
            title: '查询条件',
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  '患者 ID（用于患者相关接口）',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _patientIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '请输入患者 ID'),
                ),
              ),
            ],
          ),
          DoctorSectionCard(
            title: '患者管理',
            subtitle: 'patients=${patientState.data.items.length}',
            errorMessage: patientState.errorMessage,
            loading: patientState.isLoading,
            actions: <Widget>[
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorPatientControllerProvider.notifier)
                    .refresh(),
                child: const Text('刷新患者列表'),
              ),
            ],
          ),
          DoctorSectionCard(
            title: '量表分析',
            subtitle:
                'trends=${scaleState.data.trends.length}, report=${scaleState.data.report == null ? '未生成' : '已生成'}',
            errorMessage: scaleState.errorMessage,
            loading: scaleState.isLoading,
            actions: <Widget>[
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorScaleControllerProvider.notifier)
                    .loadTrends(patientUserId: _patientUserId),
                child: const Text('加载趋势'),
              ),
              FilledButton.tonal(
                onPressed: () => _onShowMessage(
                  ref
                      .read(doctorScaleControllerProvider.notifier)
                      .generateReport(patientUserId: _patientUserId),
                ),
                child: const Text('生成报告'),
              ),
            ],
          ),
          DoctorSectionCard(
            title: '代管用药',
            subtitle: 'items=${medicationState.data.items.length}',
            errorMessage: medicationState.errorMessage,
            loading: medicationState.isLoading,
            actions: <Widget>[
              FilledButton.tonal(
                onPressed: () => ref
                    .read(doctorMedicationControllerProvider.notifier)
                    .refresh(patientUserId: _patientUserId),
                child: const Text('刷新用药'),
              ),
              FilledButton.tonal(
                onPressed: () => _onShowMessage(
                  ref
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
                ),
                child: const Text('新建示例用药'),
              ),
            ],
          ),
          DoctorSectionCard(
            title: '观察指标汇总',
            subtitle:
                'summary=${monitorState.data.summary.length}, weight=${monitorState.data.weightTrend.length}',
            errorMessage: monitorState.errorMessage,
            loading: monitorState.isLoading,
            actions: <Widget>[
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

  Future<void> _onShowMessage(Future<String?> futureMessage) async {
    final message = await futureMessage;
    if (!mounted || message == null || message.isEmpty) return;
    _showSnack(message);
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
