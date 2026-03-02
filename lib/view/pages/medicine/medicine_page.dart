import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/medication/domain/entities/medication_entities.dart';
import 'package:mindisle_client/features/medication/presentation/editor/medication_editor_args.dart';
import 'package:mindisle_client/features/medication/presentation/list/medication_list_controller.dart';
import 'package:mindisle_client/features/medication/presentation/list/medication_list_state.dart';
import 'package:mindisle_client/view/pages/medicine/medication_editor_page.dart';
import 'package:mindisle_client/view/pages/medicine/widgets/medication_group_section.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/app_dialog.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class MedicinePage extends ConsumerStatefulWidget {
  const MedicinePage({super.key});

  static final route = AppRoute<void>(
    path: '/home/medicine',
    builder: (_) => const MedicinePage(),
  );

  @override
  ConsumerState<MedicinePage> createState() => _MedicinePageState();
}

class _MedicinePageState extends ConsumerState<MedicinePage> {
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(medicationListControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MedicationListState>(medicationListControllerProvider, (
      previous,
      next,
    ) {
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      if (message == _lastErrorMessage) return;
      _lastErrorMessage = message;
      _showSnack(message);
    });

    final state = ref.watch(medicationListControllerProvider);
    final controller = ref.read(medicationListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用药'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _buildBody(
          state: state,
          controller: controller,
        ),
      ),
    );
  }

  Widget _buildBody({
    required MedicationListState state,
    required MedicationListController controller,
  }) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicatorM3E());
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: state.items.isEmpty
            ? const [_MedicationEmptyState()]
            : [
                _MedicationSummary(
                  activeCount: state.activeItems.length,
                  totalCount: state.items.length,
                ),
                const SizedBox(height: 6),
                MedicationGroupSection(
                  title: '进行中',
                  items: state.activeItems,
                  deletingMedicationId: state.deletingMedicationId,
                  onTapItem: _openEditor,
                  onDeleteItem: _confirmDelete,
                ),
                const SizedBox(height: 6),
                MedicationGroupSection(
                  title: '已结束',
                  items: state.inactiveItems,
                  deletingMedicationId: state.deletingMedicationId,
                  onTapItem: _openEditor,
                  onDeleteItem: _confirmDelete,
                ),
              ],
      ),
    );
  }

  Future<void> _openEditor([MedicationRecord? initial]) async {
    final changed = await MedicationEditorPage.route.go(
      context,
      MedicationEditorArgs(initial: initial),
    );

    if (!mounted || changed != true) return;

    final successText = initial == null ? '已添加药品' : '已保存修改';
    _showSnack(successText);
    await ref.read(medicationListControllerProvider.notifier).refresh();
  }

  Future<void> _confirmDelete(MedicationRecord record) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        return buildAppAlertDialog(
          title: const Text('删除药品'),
          content: Text('确认删除“${record.drugName}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: errorColor),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final message = await ref
        .read(medicationListControllerProvider.notifier)
        .deleteMedication(record.medicationId);

    if (!mounted) return;
    if (message == '已删除') {
      _showSnack(message!);
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MedicationEmptyState extends StatelessWidget {
  const _MedicationEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无用药记录',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '点击右下角加号添加药品',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationSummary extends StatelessWidget {
  const _MedicationSummary({
    required this.activeCount,
    required this.totalCount,
  });

  final int activeCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Text(
          '进行中 $activeCount 条，共 $totalCount 条',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
