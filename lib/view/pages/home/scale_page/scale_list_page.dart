import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/scale/presentation/list/scale_list_controller.dart';
import 'package:mindisle_client/features/scale/presentation/list/scale_list_state.dart';
import 'package:mindisle_client/features/scale/presentation/assessment/scale_assessment_args.dart';
import 'package:mindisle_client/view/pages/home/scale_page/scale_assessment_page.dart';
import 'package:mindisle_client/view/pages/home/scale_page/scale_history_page.dart';
import 'package:mindisle_client/view/pages/home/scale_page/widgets/scale_card_tile.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class ScaleListPage extends ConsumerStatefulWidget {
  const ScaleListPage({super.key});

  static final route = AppRoute<void>(
    path: '/home/scale',
    builder: (_) => const ScaleListPage(),
  );

  @override
  ConsumerState<ScaleListPage> createState() => _ScaleListPageState();
}

class _ScaleListPageState extends ConsumerState<ScaleListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(scaleListControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScaleListState>(scaleListControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null ||
          message.isEmpty ||
          message == previous?.errorMessage) {
        return;
      }

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(message)));
      ref.read(scaleListControllerProvider.notifier).clearError();
    });

    final state = ref.watch(scaleListControllerProvider);
    final controller = ref.read(scaleListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('量表评估'),
        actions: [
          IconButton(
            tooltip: '历史记录',
            onPressed: () {
              ScaleHistoryPage.route.go(context);
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => controller.loadScales(refresh: true),
                child: state.items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: const [
                          SizedBox(height: 32),
                          Center(child: Text('当前暂无可用量表，下拉可重试。')),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                        itemCount: state.items.length,
                        itemBuilder: (itemContext, index) {
                          final item = state.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ScaleCardTile(
                              title: item.name,
                              subtitle: item.description,
                              code: item.code,
                              lastCompletedAt: item.lastCompletedAt,
                              isOpening: state.openingScaleId == item.scaleId,
                              onTap: () async {
                                final session = await controller.openScale(
                                  item,
                                );
                                if (!itemContext.mounted || session == null) {
                                  return;
                                }

                                await ScaleAssessmentPage.route.go(
                                  itemContext,
                                  ScaleAssessmentArgs(
                                    scaleId: item.scaleId,
                                    sessionId: session.sessionId,
                                  ),
                                );
                                if (!itemContext.mounted) return;
                                await controller.loadScales(refresh: true);
                              },
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
