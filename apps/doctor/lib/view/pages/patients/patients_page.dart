import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_patient/domain/entities/doctor_patient_entities.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_controller.dart';
import 'package:doctor/features/doctor_patient/presentation/patient/doctor_patient_state.dart';
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
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final initialQuery = ref.read(doctorPatientControllerProvider).data.query;
    _searchController.text = initialQuery.keyword ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(doctorPatientControllerProvider.notifier).refresh();
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
                            onLongPress: () => _editGrouping(patient),
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

  Future<void> _onRefresh() {
    return ref.read(doctorPatientControllerProvider.notifier).refresh();
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
    final nextQuery = await showModalBottomSheet<DoctorPatientQuery>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PatientFilterSortSheet(query: currentQuery),
    );
    if (!mounted || nextQuery == null) return;
    await ref
        .read(doctorPatientControllerProvider.notifier)
        .applyQuery(nextQuery);
  }

  Future<void> _editGrouping(DoctorPatient patient) async {
    final input = await showDialog<String?>(
      context: context,
      builder: (context) => _EditGroupingDialog(patient: patient),
    );
    if (!mounted || input == null) return;

    final severityGroup = _normalizeText(input);
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
  const _PatientFilterSortSheet({required this.query});

  final DoctorPatientQuery query;

  @override
  State<_PatientFilterSortSheet> createState() =>
      _PatientFilterSortSheetState();
}

class _PatientFilterSortSheetState extends State<_PatientFilterSortSheet> {
  late DoctorPatientGenderFilter? _gender;
  late bool? _abnormalOnly;
  late DoctorPatientSortBy _sortBy;
  late DoctorSortOrder _sortOrder;
  late final TextEditingController _groupController;
  late final TextEditingController _sclMinController;
  late final TextEditingController _sclMaxController;

  @override
  void initState() {
    super.initState();
    _gender = widget.query.gender;
    _abnormalOnly = widget.query.abnormalOnly;
    _sortBy = widget.query.sortBy;
    _sortOrder = widget.query.sortOrder;
    _groupController = TextEditingController(
      text: widget.query.severityGroup ?? '',
    );
    _sclMinController = TextEditingController(
      text: widget.query.scl90ScoreMin?.toString() ?? '',
    );
    _sclMaxController = TextEditingController(
      text: widget.query.scl90ScoreMax?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _groupController.dispose();
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
            TextField(
              controller: _groupController,
              decoration: const InputDecoration(
                labelText: '分组',
                hintText: '输入分组名称，留空表示不过滤',
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
      _groupController.clear();
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
      severityGroup: _normalizeText(_groupController.text),
      abnormalOnly: _abnormalOnly,
      scl90ScoreMin: min,
      scl90ScoreMax: max,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    Navigator.of(context).pop(nextQuery);
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
    required this.onLongPress,
  });

  final DoctorPatient patient;
  final bool isUpdatingGrouping;
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onLongPress: isUpdatingGrouping ? null : onLongPress,
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
                      groupText,
                      style: smallTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUpdatingGrouping) ...[
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
  const _EditGroupingDialog({required this.patient});

  final DoctorPatient patient;

  @override
  State<_EditGroupingDialog> createState() => _EditGroupingDialogState();
}

class _EditGroupingDialogState extends State<_EditGroupingDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.patient.severityGroup ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '分组',
              hintText: '留空表示清除分组',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
        ],
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
