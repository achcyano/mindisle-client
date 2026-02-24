import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/core/result/result.dart';
import 'package:mindisle_client/features/scale/domain/entities/scale_entities.dart';
import 'package:mindisle_client/features/scale/presentation/providers/scale_providers.dart';
import 'package:mindisle_client/view/pages/home/scale_page/widgets/scale_dimension_result_list.dart';
import 'package:mindisle_client/view/pages/home/scale_page/widgets/scale_result_summary_card.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ScaleResultPage extends ConsumerStatefulWidget {
  const ScaleResultPage({super.key, required this.sessionId});

  final int sessionId;

  static final route = AppRouteArg<void, int>(
    path: '/home/scale/result',
    builder: (sessionId) => ScaleResultPage(sessionId: sessionId),
  );

  @override
  ConsumerState<ScaleResultPage> createState() => _ScaleResultPageState();
}

class _ScaleResultPageState extends ConsumerState<ScaleResultPage> {
  bool _isLoading = false;
  ScaleResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResult();
    });
  }

  Future<void> _loadResult() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(fetchScaleSessionResultUseCaseProvider)
        .execute(sessionId: widget.sessionId);

    if (!mounted) return;
    switch (result) {
      case Failure<ScaleResult>(error: final error):
        var message = error.message;
        if (error.code == 40020 && error.statusCode == 409) {
          message = '结果暂未生成，请稍后重试';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
          _result = null;
        });
        return;
      case Success<ScaleResult>(data: final data):
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _result = data;
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('量表结果'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loadResult,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicatorM3E())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadResult,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            : _result == null
            ? Center(
                child: FilledButton(
                  onPressed: _loadResult,
                  child: const Text('加载结果'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                children: [
                  ScaleResultSummaryCard(result: _result!),
                  if (_result!.resultFlags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _result!.resultFlags
                              .map(
                                (flag) => Chip(
                                  side: BorderSide(
                                    width: 0.5,
                                    color: colorScheme.error.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  label: Text(flag),
                                  backgroundColor: colorScheme.errorContainer
                                      .withValues(alpha: 0.55),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ScaleDimensionResultList(result: _result!),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('返回'),
                  ),
                ],
              ),
      ),
    );
  }
}
