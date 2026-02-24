import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/history/scale_history_controller.dart';
import 'package:mindisle_client/features/scale/presentation/history/scale_history_state.dart';
import 'package:mindisle_client/view/pages/home/scale_page/scale_result_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ScaleHistoryPage extends ConsumerStatefulWidget {
  const ScaleHistoryPage({super.key});

  static final route = AppRoute<void>(
    path: '/home/scale/history',
    builder: (_) => const ScaleHistoryPage(),
  );

  @override
  ConsumerState<ScaleHistoryPage> createState() => _ScaleHistoryPageState();
}

class _ScaleHistoryPageState extends ConsumerState<ScaleHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(scaleHistoryControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScaleHistoryState>(scaleHistoryControllerProvider, (
      previous,
      next,
    ) {
      final message = next.errorMessage;
      if (message == null ||
          message.isEmpty ||
          message == previous?.errorMessage) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(message)));
      ref.read(scaleHistoryControllerProvider.notifier).clearError();
    });

    final state = ref.watch(scaleHistoryControllerProvider);
    final controller = ref.read(scaleHistoryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('量表历史')),
      body: SafeArea(
        top: false,
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicatorM3E())
            : RefreshIndicator(
                onRefresh: () => controller.loadHistory(refresh: true),
                child: state.items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        children: const [
                          SizedBox(height: 40),
                          Center(child: Text('暂无已提交量表记录。')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _HistoryTile(
                            item: item,
                            onTap: () {
                              ScaleResultPage.route.go(context, item.sessionId);
                            },
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final ScaleHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
                      item.scaleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(item.submittedAt ?? item.updatedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.totalScore == null
                    ? '--'
                    : item.totalScore!.toStringAsFixed(1),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '未知时间';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
