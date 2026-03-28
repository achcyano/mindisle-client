import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_monitor/domain/entities/doctor_monitor_entities.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/presentation/detail/doctor_patient_detail_args.dart';
import 'package:doctor/features/doctor_patient/presentation/detail/doctor_patient_detail_controller.dart';
import 'package:doctor/features/doctor_scale/domain/entities/doctor_scale_entities.dart';
import 'package:doctor/features/doctor_scale/presentation/result/doctor_scale_session_result_args.dart';
import 'package:doctor/view/pages/patients/patient_scale_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorPatientDetailPage extends ConsumerStatefulWidget {
  const DoctorPatientDetailPage({super.key, required this.args});

  final DoctorPatientDetailArgs args;

  static final route = AppRouteArg<void, DoctorPatientDetailArgs>(
    path: '/patients/detail',
    builder: (args) => DoctorPatientDetailPage(args: args),
  );

  @override
  ConsumerState<DoctorPatientDetailPage> createState() =>
      _DoctorPatientDetailPageState();
}

class _DoctorPatientDetailPageState
    extends ConsumerState<DoctorPatientDetailPage>
    with SingleTickerProviderStateMixin {
  String? _lastErrorMessage;
  late final TabController _tabController;

  bool get _isReportTabActive => _tabController.index == 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(doctorPatientDetailControllerProvider(widget.args).notifier)
          .refresh();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(doctorPatientDetailControllerProvider(widget.args), (
      previous,
      next,
    ) {
      final message = next.errorMessage?.trim() ?? '';
      if (message.isEmpty || message == _lastErrorMessage) return;
      _lastErrorMessage = message;
      _showSnack(message);
    });

    final detailState = ref.watch(
      doctorPatientDetailControllerProvider(widget.args),
    );
    final data = detailState.data;
    final controller = ref.read(
      doctorPatientDetailControllerProvider(widget.args).notifier,
    );

    final shouldShowFirstLoading =
        detailState.isLoading &&
        data.patientProfile == null &&
        data.weightTrend.isEmpty &&
        data.historyRecords.isEmpty &&
        data.reports.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.patient.fullName.trim().isNotEmpty
              ? data.patient.fullName.trim()
              : '患者详情',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '基本资料'),
            Tab(text: '量表历史'),
            Tab(text: '评估报告'),
          ],
        ),
      ),
      floatingActionButton: _isReportTabActive
          ? FloatingActionButton.extended(
              onPressed: data.isGeneratingReport
                  ? null
                  : () async {
                      final message = await controller.generateReport();
                      if (!mounted) return;
                      _showSnack(message ?? '评估报告已重新生成');
                    },
              icon: data.isGeneratingReport
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(data.isGeneratingReport ? '生成中…' : '重新生成'),
            )
          : null,
      body: SafeArea(
        top: false,
        child: shouldShowFirstLoading
            ? const Center(child: CircularProgressIndicatorM3E())
            : TabBarView(
                controller: _tabController,
                children: [
                  _BasicInfoTab(
                    patient: data.patient,
                    profile: data.patientProfile,
                    weightTrend: data.weightTrend,
                    isLoading: data.isBasicLoading,
                    errorMessage: data.basicErrorMessage,
                    onRefresh: controller.refreshBasicTab,
                  ),
                  _ScaleHistoryTab(
                    records: data.historyRecords,
                    isLoading: data.isHistoryLoading,
                    errorMessage: data.historyErrorMessage,
                    hasMore: data.hasMoreHistory,
                    isLoadingMore: data.isLoadingMoreHistory,
                    onRefresh: () => controller.refreshHistoryTab(reset: true),
                    onLoadMore: controller.loadMoreHistory,
                    onOpenRecord: _openScaleSessionResult,
                  ),
                  _ReportTab(
                    reports: data.reports,
                    isLoading: data.isReportLoading,
                    hasMore: data.hasMoreReports,
                    isLoadingMore: data.isLoadingMoreReports,
                    errorMessage: data.reportErrorMessage,
                    onRefresh: () =>
                        controller.refreshReportTab(resetList: true),
                    onLoadMore: controller.loadMoreReports,
                    onOpenReport: (report) => _openReportById(report.reportId),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _openReportById(int reportId) async {
    final controller = ref.read(
      doctorPatientDetailControllerProvider(widget.args).notifier,
    );
    final detail = await controller.openReportDetail(reportId: reportId);
    if (!mounted) return;
    if (detail == null) {
      final state = ref.read(
        doctorPatientDetailControllerProvider(widget.args),
      );
      final message = state.data.reportDetailErrors[reportId]?.trim();
      _showSnack(message?.isNotEmpty == true ? message! : '报告详情加载失败，请稍后重试');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReportDetailSheet(detail: detail),
    );
  }

  Future<void> _openScaleSessionResult(DoctorScaleAnswerRecord record) async {
    final sessionId = record.sessionId;
    if (sessionId == null || sessionId <= 0) {
      _showSnack('该条记录缺少会话标识，暂时无法查看结果');
      return;
    }
    await DoctorScaleSessionResultPage.route.goRoot(
      context,
      DoctorScaleSessionResultArgs(
        patientUserId: widget.args.patient.patientUserId,
        sessionId: sessionId,
        scaleId: record.scaleId,
        scaleCode: record.scaleCode,
        scaleName: record.scaleName,
      ),
    );
  }

  void _showSnack(String message) {
    final text = message.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(text)));
  }
}

class _BasicInfoTab extends StatelessWidget {
  const _BasicInfoTab({
    required this.patient,
    required this.profile,
    required this.weightTrend,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  });

  final DoctorPatient patient;
  final DoctorPatientProfile? profile;
  final List<WeightTrendPoint> weightTrend;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage?.trim().isNotEmpty == true;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          if (isLoading && profile == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Center(child: CircularProgressIndicatorM3E()),
            ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RetryErrorCard(
                title: '基本资料加载失败',
                message: errorMessage!.trim(),
                onRetry: onRefresh,
                isRetrying: isLoading,
              ),
            ),
          _PatientProfileCard(patient: patient, profile: profile),
          const SizedBox(height: 8),
          _WeightTrendSection(
            profileWeightKg: profile?.weightKg,
            weightTrend: weightTrend,
          ),
        ],
      ),
    );
  }
}

class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({required this.patient, required this.profile});

  final DoctorPatient patient;
  final DoctorPatientProfile? profile;

  @override
  Widget build(BuildContext context) {
    final smallText = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final birthDate = profile?.birthDate ?? patient.birthDate;
    final age = patient.age ?? _calculateAge(birthDate);
    final diseaseHistoryText = _formatHistory(profile?.diseaseHistory);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (profile?.fullName ?? patient.fullName).trim().isNotEmpty
                  ? (profile?.fullName ?? patient.fullName)
                  : '未命名患者',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: '手机号',
              value: _textOrFallback(profile?.phone ?? patient.phone, '未绑定手机号'),
              style: smallText,
            ),
            _InfoRow(
              label: '性别',
              value: _genderLabel(profile?.gender ?? patient.gender),
              style: smallText,
            ),
            _InfoRow(
              label: '出生日期',
              value: birthDate == null ? '未填写' : _formatDate(birthDate),
              style: smallText,
            ),
            _InfoRow(
              label: '年龄',
              value: age == null ? '未填写' : '$age 岁',
              style: smallText,
            ),
            _InfoRow(
              label: '身高',
              value: profile?.heightCm == null
                  ? '未填写'
                  : '${profile!.heightCm!.toStringAsFixed(1)} cm',
              style: smallText,
            ),
            _InfoRow(
              label: '体重',
              value: profile?.weightKg == null
                  ? '未填写'
                  : '${profile!.weightKg!.toStringAsFixed(1)} kg',
              style: smallText,
            ),
            _InfoRow(
              label: '腰围',
              value: profile?.waistCm == null
                  ? '未填写'
                  : '${profile!.waistCm!.toStringAsFixed(1)} cm',
              style: smallText,
            ),
            _InfoRow(
              label: '是否使用中药',
              value: switch (profile?.usesTcm) {
                true => '是',
                false => '否',
                null => '未填写',
              },
              style: smallText,
            ),
            _InfoRow(label: '疾病史', value: diseaseHistoryText, style: smallText),
          ],
        ),
      ),
    );
  }

  String _textOrFallback(String? value, String fallback) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  String _genderLabel(DoctorPatientGender? gender) {
    return switch (gender) {
      DoctorPatientGender.male => '男',
      DoctorPatientGender.female => '女',
      DoctorPatientGender.other => '其他',
      DoctorPatientGender.unknown => '未知',
      null => '未知',
    };
  }

  String _formatHistory(List<String>? source) {
    if (source == null || source.isEmpty) return '无';
    final values = source
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) return '无';
    return values.join('、');
  }

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final reachedBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!reachedBirthday) age -= 1;
    if (age < 0) return null;
    return age;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.style,
  });

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label：$value', style: style),
    );
  }
}

class _WeightTrendSection extends StatelessWidget {
  const _WeightTrendSection({
    required this.profileWeightKg,
    required this.weightTrend,
  });

  final double? profileWeightKg;
  final List<WeightTrendPoint> weightTrend;

  @override
  Widget build(BuildContext context) {
    final points = [
      for (var index = 0; index < weightTrend.length; index++)
        if (weightTrend[index].date != null &&
            weightTrend[index].weightKg != null)
          ScaleTrendPoint(
            sessionId: index + 1,
            time: weightTrend[index].date!,
            score: weightTrend[index].weightKg!,
          ),
    ]..sort((a, b) => a.time.compareTo(b.time));

    final smallStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final records = points.reversed.toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (points.length >= 3)
          ScaleScoreTrendChartCard(
            points: points,
            title: '体重变化趋势',
            scoreLabel: '体重(kg)',
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('体重记录', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text('共 ${records.length} 次记录', style: smallStyle),
                const SizedBox(height: 8),
                if (records.isNotEmpty)
                  ...records.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${_formatDate(point.time)}  ${point.score.toStringAsFixed(1)} kg',
                        style: smallStyle,
                      ),
                    ),
                  )
                else if (profileWeightKg != null)
                  Text(
                    '当前体重：${profileWeightKg!.toStringAsFixed(1)} kg',
                    style: smallStyle,
                  )
                else
                  Text('暂无记录', style: smallStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScaleHistoryTab extends StatelessWidget {
  const _ScaleHistoryTab({
    required this.records,
    required this.isLoading,
    required this.errorMessage,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpenRecord,
  });

  final List<DoctorScaleAnswerRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(DoctorScaleAnswerRecord record) onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final smallStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final hasError = errorMessage?.trim().isNotEmpty == true;

    if (isLoading && records.isEmpty) {
      return const Center(child: CircularProgressIndicatorM3E());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: records.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              children: [
                if (hasError)
                  RetryErrorCard(
                    title: '量表历史加载失败',
                    message: errorMessage!.trim(),
                    onRetry: onRefresh,
                  )
                else
                  const Center(child: Text('暂无量表作答记录')),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RetryErrorCard(
                      title: '量表历史加载失败',
                      message: errorMessage!.trim(),
                      onRetry: onRefresh,
                    ),
                  ),
                for (final record in records) ...[
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onOpenRecord(record),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            const Icon(Icons.assessment_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.scaleName?.trim().isNotEmpty == true
                                        ? record.scaleName!
                                        : '量表作答',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(record.answeredAt),
                                    style: smallStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              record.numericScore == null
                                  ? '--'
                                  : record.numericScore!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Center(child: CircularProgressIndicatorM3E()),
                  )
                else if (hasMore)
                  Center(
                    child: OutlinedButton(
                      onPressed: onLoadMore,
                      child: const Text('加载更多记录'),
                    ),
                  )
                else
                  Center(child: Text('没有更多记录了', style: smallStyle)),
              ],
            ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab({
    required this.reports,
    required this.isLoading,
    required this.hasMore,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpenReport,
  });

  final List<DoctorAssessmentReportSummary> reports;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final Future<void> Function(DoctorAssessmentReportSummary report)
  onOpenReport;

  @override
  Widget build(BuildContext context) {
    final smallStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final hasError = errorMessage?.trim().isNotEmpty == true;

    if (isLoading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicatorM3E());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('报告列表', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (hasError && reports.isEmpty) ...[
                    Text(
                      '评估报告加载失败',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(errorMessage!.trim(), style: smallStyle),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ] else if (reports.isEmpty)
                    Text('暂无报告', style: smallStyle)
                  else
                    ...reports.map(
                      (report) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          report.scaleName?.trim().isNotEmpty == true
                              ? report.scaleName!
                              : '报告 #${report.reportId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_formatDateTime(report.generatedAt)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onOpenReport(report),
                      ),
                    ),
                  if (hasError && reports.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('加载更多失败：${errorMessage!.trim()}', style: smallStyle),
                  ],
                  if (isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Center(child: CircularProgressIndicatorM3E()),
                    )
                  else if (hasMore)
                    Center(
                      child: OutlinedButton(
                        onPressed: onLoadMore,
                        child: const Text('加载更多报告'),
                      ),
                    )
                  else if (reports.isNotEmpty)
                    Center(child: Text('没有更多报告了', style: smallStyle)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.detail});

  final DoctorAssessmentReportDetail detail;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary?.trim();
    final bodySmall = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: ListView(
        children: [
          Text(
            '报告 #${detail.reportId}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(_formatDateTime(detail.generatedAt), style: bodySmall),
          const SizedBox(height: 12),
          if (summary != null && summary.isNotEmpty) ...[
            Text('分析结论', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(summary),
            const SizedBox(height: 12),
          ],
          Text('原始作答答案', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          if (detail.answerRecords.isEmpty)
            Text('暂无原始作答答案', style: bodySmall)
          else
            ...detail.answerRecords.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.questionText),
                subtitle: Text(item.answerText),
                dense: true,
              ),
            ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '未知时间';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
