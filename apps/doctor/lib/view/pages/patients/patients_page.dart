import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/presentation/detail/doctor_patient_detail_args.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_controller.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_state.dart';
import 'package:doctor/view/pages/patients/patient_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _updatingGroupPatientIds = <int>{};
  final Set<int> _updatingDiagnosisPatientIds = <int>{};
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final initialQuery = ref.read(doctorPatientControllerProvider).data.query;
    _searchController.text = initialQuery.keyword ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(doctorPatientControllerProvider.notifier);
      controller.refresh();
      controller.loadGroupOptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DoctorPatientState>(doctorPatientControllerProvider, (
      previous,
      next,
    ) {
      final message = next.errorMessage?.trim() ?? '';
      if (message.isEmpty || message == _lastErrorMessage) return;
      _lastErrorMessage = message;
      _showSnack(message);
    });

    final patientState = ref.watch(doctorPatientControllerProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleSpacing: 16,
        title: _AppBarSearchField(
          controller: _searchController,
          onSearchChanged: () => setState(() {}),
          onSearchSubmit: _applyKeyword,
        ),
        actions: [
          IconButton(
            tooltip: '筛选与排序',
            onPressed: () => _openFilterSortSheet(patientState.data.query),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: patientState.isLoading && patientState.data.items.isEmpty
          ? const Center(child: CircularProgressIndicatorM3E())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _PatientTopBar(
                      hasKeyword:
                          patientState.data.query.keyword?.trim().isNotEmpty ==
                          true,
                      activeFilterCount:
                          patientState.data.query.activeFilterCount,
                      currentSortBy: patientState.data.query.sortBy,
                      currentSortOrder: patientState.data.query.sortOrder,
                      onResetTap: _resetQuery,
                    ),
                  ),
                  if (patientState.data.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child:
                            patientState.errorMessage?.trim().isNotEmpty == true
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: RetryErrorCard(
                                  title: '获取患者列表失败',
                                  message: patientState.errorMessage!.trim(),
                                  onRetry: () {
                                    ref
                                        .read(
                                          doctorPatientControllerProvider
                                              .notifier,
                                        )
                                        .refresh(clearItems: true);
                                  },
                                  isRetrying:
                                      patientState.isLoading ||
                                      patientState.data.isRefreshing,
                                ),
                              )
                            : _EmptyPatientsState(
                                keyword: patientState.data.query.keyword,
                              ),
                      ),
                    )
                  else ...[
                    if (patientState.errorMessage?.trim().isNotEmpty == true)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: RetryErrorCard(
                            title: '列表加载出现问题',
                            message: patientState.errorMessage!.trim(),
                            onRetry: () => ref
                                .read(doctorPatientControllerProvider.notifier)
                                .refresh(),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index.isOdd) return const SizedBox(height: 8);
                          final patient = patientState.data.items[index ~/ 2];
                          return _PatientCard(
                            patient: patient,
                            isUpdatingGrouping: _updatingGroupPatientIds
                                .contains(patient.patientUserId),
                            isUpdatingDiagnosis: _updatingDiagnosisPatientIds
                                .contains(patient.patientUserId),
                            onTap: () => DoctorPatientDetailPage.route.goRoot(
                              context,
                              DoctorPatientDetailArgs(patient: patient),
                            ),
                            onLongPress: () => _openManageSheet(patient),
                          );
                        }, childCount: patientState.data.items.length * 2 - 1),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: _PaginationFooter(
                          isLoadingMore: patientState.data.isLoadingMore,
                          hasMore: patientState.data.hasMore,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _onRefresh() async {
    final controller = ref.read(doctorPatientControllerProvider.notifier);
    await controller.refresh();
    await controller.loadGroupOptions(force: true);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 160) return;
    ref.read(doctorPatientControllerProvider.notifier).loadMore();
  }

  Future<void> _applyKeyword() async {
    final keyword = _normalizeText(_searchController.text);
    final currentQuery = ref.read(doctorPatientControllerProvider).data.query;
    if (keyword == currentQuery.keyword) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(doctorPatientControllerProvider.notifier)
        .applyQuery(currentQuery.copyWith(keyword: keyword));
  }

  Future<void> _resetQuery() async {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    await ref
        .read(doctorPatientControllerProvider.notifier)
        .applyQuery(const DoctorPatientQuery());
  }

  Future<void> _openFilterSortSheet(DoctorPatientQuery currentQuery) async {
    final currentState = ref.read(doctorPatientControllerProvider);
    final nextQuery = await showModalBottomSheet<DoctorPatientQuery>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PatientFilterSortSheet(
        query: currentQuery,
        groupOptions: currentState.data.groupOptions,
        onCreateGroup: _createGroup,
      ),
    );
    if (!mounted || nextQuery == null) return;
    await ref
        .read(doctorPatientControllerProvider.notifier)
        .applyQuery(nextQuery);
  }

  Future<void> _openManageSheet(DoctorPatient patient) async {
    final action = await showModalBottomSheet<_PatientManageAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: const Text('编辑分组'),
              onTap: () =>
                  Navigator.of(context).pop(_PatientManageAction.editGroup),
            ),
            ListTile(
              leading: const Icon(Icons.medical_information_outlined),
              title: const Text('编辑诊断'),
              onTap: () =>
                  Navigator.of(context).pop(_PatientManageAction.editDiagnosis),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _PatientManageAction.editGroup:
        await _editGrouping(patient);
      case _PatientManageAction.editDiagnosis:
        await _editDiagnosis(patient);
    }
  }

  Future<void> _editGrouping(DoctorPatient patient) async {
    final groups = ref.read(doctorPatientControllerProvider).data.groupOptions;
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => _EditGroupingDialog(
        patient: patient,
        groupOptions: groups,
        onCreateGroup: _createGroup,
      ),
    );
    if (!mounted || selected == null) return;

    final severityGroup = _normalizeText(selected);
    setState(() {
      _updatingGroupPatientIds.add(patient.patientUserId);
    });

    try {
      final message = await ref
          .read(doctorPatientControllerProvider.notifier)
          .updateGrouping(
            patientUserId: patient.patientUserId,
            payload: DoctorPatientGrouping(severityGroup: severityGroup),
          );
      if (!mounted) return;
      if (message != null && message.trim().isNotEmpty) {
        _showSnack(message);
        return;
      }
      _showSnack(severityGroup == null ? '已清除分组' : '分组已更新');
    } finally {
      if (mounted) {
        setState(() {
          _updatingGroupPatientIds.remove(patient.patientUserId);
        });
      }
    }
  }

  Future<void> _editDiagnosis(DoctorPatient patient) async {
    final text = await showDialog<String?>(
      context: context,
      builder: (context) => _EditDiagnosisDialog(patient: patient),
    );
    if (!mounted || text == null) return;
    final diagnosis = _normalizeText(text);
    setState(() {
      _updatingDiagnosisPatientIds.add(patient.patientUserId);
    });
    try {
      final message = await ref
          .read(doctorPatientControllerProvider.notifier)
          .updateDiagnosis(
            patientUserId: patient.patientUserId,
            payload: DoctorPatientDiagnosisUpdatePayload(diagnosis: diagnosis),
          );
      if (!mounted) return;
      if (message != null && message.trim().isNotEmpty) {
        _showSnack(message);
        return;
      }
      _showSnack(diagnosis == null ? '已清除诊断' : '诊断已更新');
    } finally {
      if (mounted) {
        setState(() {
          _updatingDiagnosisPatientIds.remove(patient.patientUserId);
        });
      }
    }
  }

  Future<String?> _createGroup(String input) async {
    final severityGroup = _normalizeText(input);
    if (severityGroup == null) {
      return '分组名称不能为空';
    }
    final message = await ref
        .read(doctorPatientControllerProvider.notifier)
        .createGroup(severityGroup: severityGroup);
    if (mounted && message != null && message.trim().isNotEmpty) {
      _showSnack(message);
    }
    return message;
  }

  String? _normalizeText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _PatientManageAction { editGroup, editDiagnosis }

class _AppBarSearchField extends StatelessWidget {
  const _AppBarSearchField({
    required this.controller,
    required this.onSearchChanged,
    required this.onSearchSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSearchChanged;
  final VoidCallback onSearchSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKeyword = controller.text.trim().isNotEmpty;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: (_) => onSearchChanged(),
      onSubmitted: (_) => onSearchSubmit(),
      decoration: InputDecoration(
        hintText: '按姓名或手机号搜索',
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLow,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: SizedBox(
          width: hasKeyword ? 96 : 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasKeyword)
                IconButton(
                  tooltip: '清空',
                  onPressed: () {
                    controller.clear();
                    onSearchChanged();
                    onSearchSubmit();
                  },
                  icon: const Icon(Icons.close),
                ),
              IconButton(
                tooltip: '搜索',
                onPressed: onSearchSubmit,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.42),
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _PatientTopBar extends StatelessWidget {
  const _PatientTopBar({
    required this.hasKeyword,
    required this.activeFilterCount,
    required this.currentSortBy,
    required this.currentSortOrder,
    required this.onResetTap,
  });

  final bool hasKeyword;
  final int activeFilterCount;
  final DoctorPatientSortBy currentSortBy;
  final DoctorSortOrder currentSortOrder;
  final VoidCallback onResetTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showReset = hasKeyword || activeFilterCount > 0;
    final summaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              activeFilterCount > 0
                  ? '筛选 $activeFilterCount 项，排序：${currentSortBy.label}（${currentSortOrder.label}）'
                  : '排序：${currentSortBy.label}（${currentSortOrder.label}）',
              style: summaryStyle,
            ),
          ),
          if (showReset)
            TextButton(onPressed: onResetTap, child: const Text('清空条件')),
        ],
      ),
    );
  }
}

class _PatientFilterSortSheet extends StatefulWidget {
  const _PatientFilterSortSheet({
    required this.query,
    required this.groupOptions,
    required this.onCreateGroup,
  });

  final DoctorPatientQuery query;
  final List<DoctorPatientGroupOption> groupOptions;
  final Future<String?> Function(String input) onCreateGroup;

  @override
  State<_PatientFilterSortSheet> createState() =>
      _PatientFilterSortSheetState();
}

class _PatientFilterSortSheetState extends State<_PatientFilterSortSheet> {
  late DoctorPatientGenderFilter? _gender;
  late bool? _abnormalOnly;
  late DoctorPatientSortBy _sortBy;
  late DoctorSortOrder _sortOrder;
  late String? _selectedGroup;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _sclMinController;
  late final TextEditingController _sclMaxController;
  late List<DoctorPatientGroupOption> _groupOptions;
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    _gender = widget.query.gender;
    _abnormalOnly = widget.query.abnormalOnly;
    _sortBy = widget.query.sortBy;
    _sortOrder = widget.query.sortOrder;
    _selectedGroup = widget.query.severityGroup?.trim();
    _diagnosisController = TextEditingController(
      text: widget.query.diagnosisKeyword ?? '',
    );
    _sclMinController = TextEditingController(
      text: widget.query.scl90ScoreMin?.toString() ?? '',
    );
    _sclMaxController = TextEditingController(
      text: widget.query.scl90ScoreMax?.toString() ?? '',
    );
    _groupOptions = widget.groupOptions.toList(growable: false);
    if (_selectedGroup != null &&
        _selectedGroup!.isNotEmpty &&
        !_groupOptions.any((item) => item.severityGroup == _selectedGroup)) {
      _groupOptions = [
        ..._groupOptions,
        DoctorPatientGroupOption(
          severityGroup: _selectedGroup!,
          patientCount: 0,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _sclMinController.dispose();
    _sclMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + viewInsetsBottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('筛选与排序', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<DoctorPatientGenderFilter?>(
              key: ValueKey<String>('gender-${_gender?.name ?? 'all'}'),
              initialValue: _gender,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '性别'),
              items: const [
                DropdownMenuItem<DoctorPatientGenderFilter?>(
                  value: null,
                  child: Text('全部'),
                ),
                DropdownMenuItem<DoctorPatientGenderFilter?>(
                  value: DoctorPatientGender.unknown,
                  child: Text('未知'),
                ),
                DropdownMenuItem<DoctorPatientGenderFilter?>(
                  value: DoctorPatientGender.male,
                  child: Text('男'),
                ),
                DropdownMenuItem<DoctorPatientGenderFilter?>(
                  value: DoctorPatientGender.female,
                  child: Text('女'),
                ),
                DropdownMenuItem<DoctorPatientGenderFilter?>(
                  value: DoctorPatientGender.other,
                  child: Text('其他'),
                ),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey<String>('group-${_selectedGroup ?? 'all'}'),
                    initialValue: _selectedGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '分组'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部'),
                      ),
                      for (final item in _groupOptions)
                        DropdownMenuItem<String?>(
                          value: item.severityGroup,
                          child: Text(
                            item.patientCount > 0
                                ? '${item.severityGroup}（${item.patientCount}）'
                                : item.severityGroup,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedGroup = value),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _isCreatingGroup ? null : _createGroup,
                  icon: _isCreatingGroup
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('新增'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: '诊断关键字（本地筛选）',
                hintText: '输入后按本地诊断文本筛选',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool?>(
              key: ValueKey<String>(
                'abnormal-${_abnormalOnly == null ? 'all' : _abnormalOnly.toString()}',
              ),
              initialValue: _abnormalOnly,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '问卷异常'),
              items: const [
                DropdownMenuItem<bool?>(value: null, child: Text('全部')),
                DropdownMenuItem<bool?>(value: true, child: Text('仅异常')),
                DropdownMenuItem<bool?>(value: false, child: Text('仅正常')),
              ],
              onChanged: (value) => setState(() => _abnormalOnly = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sclMinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'SCL-90 最低分'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sclMaxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'SCL-90 最高分'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DoctorPatientSortBy>(
              key: ValueKey<String>('sort-by-${_sortBy.name}'),
              initialValue: _sortBy,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '排序字段'),
              items: const [
                DropdownMenuItem<DoctorPatientSortBy>(
                  value: DoctorPatientSortBy.latestAssessmentAt,
                  child: Text('最近评估时间'),
                ),
                DropdownMenuItem<DoctorPatientSortBy>(
                  value: DoctorPatientSortBy.scl90Score,
                  child: Text('SCL-90 分数'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sortBy = value);
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<DoctorSortOrder>(
              selected: <DoctorSortOrder>{_sortOrder},
              segments: const <ButtonSegment<DoctorSortOrder>>[
                ButtonSegment<DoctorSortOrder>(
                  value: DoctorSortOrder.desc,
                  label: Text('降序'),
                  icon: Icon(Icons.south),
                ),
                ButtonSegment<DoctorSortOrder>(
                  value: DoctorSortOrder.asc,
                  label: Text('升序'),
                  icon: Icon(Icons.north),
                ),
              ],
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                setState(() => _sortOrder = selection.first);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: _resetLocalFilterFields,
                  child: const Text('重置'),
                ),
                const Spacer(),
                FilledButton(onPressed: _apply, child: const Text('应用')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetLocalFilterFields() {
    setState(() {
      _gender = null;
      _abnormalOnly = null;
      _sortBy = DoctorPatientSortBy.latestAssessmentAt;
      _sortOrder = DoctorSortOrder.desc;
      _selectedGroup = null;
      _diagnosisController.clear();
      _sclMinController.clear();
      _sclMaxController.clear();
    });
  }

  void _apply() {
    final minText = _normalizeText(_sclMinController.text);
    final maxText = _normalizeText(_sclMaxController.text);
    final min = minText == null ? null : double.tryParse(minText);
    final max = maxText == null ? null : double.tryParse(maxText);
    if ((minText != null && min == null) || (maxText != null && max == null)) {
      _showSnack('SCL-90 分数请输入有效数字');
      return;
    }
    if (min != null && max != null && min > max) {
      _showSnack('SCL-90 最低分不能大于最高分');
      return;
    }

    final nextQuery = widget.query.copyWith(
      gender: _gender,
      severityGroup: _selectedGroup,
      diagnosisKeyword: _normalizeText(_diagnosisController.text),
      abnormalOnly: _abnormalOnly,
      scl90ScoreMin: min,
      scl90ScoreMax: max,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    Navigator.of(context).pop(nextQuery);
  }

  Future<void> _createGroup() async {
    final text = await showDialog<String?>(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
    if (!mounted || text == null) return;
    final normalized = _normalizeText(text);
    if (normalized == null) {
      _showSnack('分组名称不能为空');
      return;
    }
    setState(() {
      _isCreatingGroup = true;
    });
    try {
      final message = await widget.onCreateGroup(normalized);
      if (!mounted) return;
      if (message != null && message.trim().isNotEmpty) {
        _showSnack(message);
        return;
      }
      setState(() {
        if (!_groupOptions.any((item) => item.severityGroup == normalized)) {
          _groupOptions = [
            ..._groupOptions,
            DoctorPatientGroupOption(
              severityGroup: normalized,
              patientCount: 0,
            ),
          ];
        }
        _selectedGroup = normalized;
      });
      _showSnack('分组已添加');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  String? _normalizeText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.isUpdatingGrouping,
    required this.isUpdatingDiagnosis,
    required this.onTap,
    required this.onLongPress,
  });

  final DoctorPatient patient;
  final bool isUpdatingGrouping;
  final bool isUpdatingDiagnosis;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final smallTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);
    final groupText = patient.severityGroup?.trim().isNotEmpty == true
        ? patient.severityGroup!.trim()
        : '未分组';
    final diagnosisText = patient.diagnosis?.trim().isNotEmpty == true
        ? patient.diagnosis!.trim()
        : '暂无诊断';
    final summaryText = '$groupText | $diagnosisText';
    final isUpdating = isUpdatingGrouping || isUpdatingDiagnosis;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: isUpdating ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      patient.fullName.trim().isNotEmpty
                          ? patient.fullName
                          : '未命名患者',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      summaryText,
                      style: smallTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUpdating) ...[
                    const SizedBox(width: 8),
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text('性别：${_genderLabel(patient.gender)}', style: smallTextStyle),
              const SizedBox(height: 4),
              Text('年龄：${_ageLabel(patient.age)}', style: smallTextStyle),
            ],
          ),
        ),
      ),
    );
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

  String _ageLabel(int? age) {
    if (age == null || age <= 0) return '未知';
    return '$age 岁';
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.isLoadingMore, required this.hasMore});

  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    if (isLoadingMore) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicatorM3E()),
      );
    }
    return SizedBox(
      height: 32,
      child: Center(child: Text(hasMore ? '上滑加载更多' : '没有更多患者了', style: style)),
    );
  }
}

class _EmptyPatientsState extends StatelessWidget {
  const _EmptyPatientsState({required this.keyword});

  final String? keyword;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('暂无患者数据', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            keyword?.trim().isNotEmpty == true ? '请调整搜索条件后重试' : '下拉可刷新患者列表',
            style: style,
          ),
        ],
      ),
    );
  }
}

class _EditGroupingDialog extends StatefulWidget {
  const _EditGroupingDialog({
    required this.patient,
    required this.groupOptions,
    required this.onCreateGroup,
  });

  final DoctorPatient patient;
  final List<DoctorPatientGroupOption> groupOptions;
  final Future<String?> Function(String input) onCreateGroup;

  @override
  State<_EditGroupingDialog> createState() => _EditGroupingDialogState();
}

class _EditGroupingDialogState extends State<_EditGroupingDialog> {
  late String? _selectedGroup;
  late List<DoctorPatientGroupOption> _groupOptions;
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.patient.severityGroup?.trim();
    _groupOptions = widget.groupOptions.toList(growable: false);
    if (_selectedGroup != null &&
        _selectedGroup!.isNotEmpty &&
        !_groupOptions.any((item) => item.severityGroup == _selectedGroup)) {
      _groupOptions = [
        ..._groupOptions,
        DoctorPatientGroupOption(
          severityGroup: _selectedGroup!,
          patientCount: 0,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑分组'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.patient.fullName.trim().isNotEmpty
                ? widget.patient.fullName
                : '未命名患者',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: ValueKey<String>('edit-group-${_selectedGroup ?? 'none'}'),
            initialValue: _selectedGroup,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '分组'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('未分组')),
              for (final item in _groupOptions)
                DropdownMenuItem<String?>(
                  value: item.severityGroup,
                  child: Text(item.severityGroup),
                ),
            ],
            onChanged: (value) => setState(() => _selectedGroup = value),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isCreatingGroup ? null : _createGroup,
              icon: _isCreatingGroup
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('新增分组'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedGroup ?? ''),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _createGroup() async {
    final text = await showDialog<String?>(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
    if (!mounted || text == null) return;
    final normalized = text.trim();
    if (normalized.isEmpty) {
      _showSnack('分组名称不能为空');
      return;
    }
    setState(() {
      _isCreatingGroup = true;
    });
    try {
      final message = await widget.onCreateGroup(normalized);
      if (!mounted) return;
      if (message != null && message.trim().isNotEmpty) {
        _showSnack(message);
        return;
      }
      setState(() {
        if (!_groupOptions.any((item) => item.severityGroup == normalized)) {
          _groupOptions = [
            ..._groupOptions,
            DoctorPatientGroupOption(
              severityGroup: normalized,
              patientCount: 0,
            ),
          ];
        }
        _selectedGroup = normalized;
      });
      _showSnack('分组已添加');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
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

class _EditDiagnosisDialog extends StatefulWidget {
  const _EditDiagnosisDialog({required this.patient});

  final DoctorPatient patient;

  @override
  State<_EditDiagnosisDialog> createState() => _EditDiagnosisDialogState();
}

class _EditDiagnosisDialogState extends State<_EditDiagnosisDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.patient.diagnosis ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑诊断'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        minLines: 1,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '诊断',
          hintText: '留空表示清除诊断',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('清除'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text);
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增分组'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '分组名称',
          hintText: '请输入分组名称',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('确定')),
      ],
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text);
  }
}
