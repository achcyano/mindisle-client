import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_binding/domain/entities/doctor_binding_entities.dart';
import 'package:doctor/features/doctor_binding/presentation/binding/doctor_binding_controller.dart';
import 'package:doctor/features/doctor_binding/presentation/binding/doctor_binding_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DoctorBindingsPage extends ConsumerStatefulWidget {
  const DoctorBindingsPage({super.key, this.currentTabIndexListenable});

  static const tabIndex = 1;

  final ValueListenable<int>? currentTabIndexListenable;

  static final route = AppRoute<void>(
    path: '/bindings',
    builder: (_) => const DoctorBindingsPage(),
  );

  @override
  ConsumerState<DoctorBindingsPage> createState() => _DoctorBindingsPageState();
}

class _DoctorBindingsPageState extends ConsumerState<DoctorBindingsPage> {
  int? _lastObservedTabIndex;

  @override
  void initState() {
    super.initState();
    _lastObservedTabIndex = widget.currentTabIndexListenable?.value;
    widget.currentTabIndexListenable?.addListener(_handleTabChanged);

    if (widget.currentTabIndexListenable == null ||
        widget.currentTabIndexListenable!.value ==
            DoctorBindingsPage.tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshBindingCode();
      });
    }
  }

  @override
  void didUpdateWidget(covariant DoctorBindingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(
      oldWidget.currentTabIndexListenable,
      widget.currentTabIndexListenable,
    )) {
      return;
    }

    oldWidget.currentTabIndexListenable?.removeListener(_handleTabChanged);
    _lastObservedTabIndex = widget.currentTabIndexListenable?.value;
    widget.currentTabIndexListenable?.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    widget.currentTabIndexListenable?.removeListener(_handleTabChanged);
    super.dispose();
  }

  void _handleTabChanged() {
    final currentTabIndex = widget.currentTabIndexListenable?.value;
    if (currentTabIndex == null) return;

    final wasVisible = _lastObservedTabIndex == DoctorBindingsPage.tabIndex;
    _lastObservedTabIndex = currentTabIndex;
    if (!wasVisible && currentTabIndex == DoctorBindingsPage.tabIndex) {
      _refreshBindingCode();
    }
  }

  Future<void> _refreshBindingCode() {
    return ref
        .read(doctorBindingControllerProvider.notifier)
        .refreshBindingCode();
  }

  @override
  Widget build(BuildContext context) {
    final bindingState = ref.watch(doctorBindingControllerProvider);
    final hasError = (bindingState.errorMessage ?? '').trim().isNotEmpty;
    final contentAlignment = hasError && bindingState.data.latestCode == null
        ? Alignment.topCenter
        : Alignment.center;

    return Scaffold(
      appBar: AppBar(title: const Text('绑定医生'), centerTitle: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshBindingCode,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: contentAlignment,
                    child: _BindingPageContent(
                      state: bindingState,
                      onRetry: _refreshBindingCode,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BindingPageContent extends StatelessWidget {
  const _BindingPageContent({required this.state, required this.onRetry});

  final DoctorBindingState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final code = state.data.latestCode;
    final errorMessage = state.errorMessage?.trim() ?? '';
    final hasError = errorMessage.isNotEmpty;

    if (code != null) {
      return _BindingCodeView(code: code);
    }

    if (hasError) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: RetryErrorCard(
          title: '获取绑定码失败',
          message: errorMessage,
          onRetry: () {
            onRetry();
          },
          isRetrying: state.isLoading,
        ),
      );
    }

    return const SizedBox(
      height: 240,
      child: Center(child: CircularProgressIndicatorM3E()),
    );
  }
}

class _BindingCodeView extends StatelessWidget {
  const _BindingCodeView({required this.code});

  final DoctorBindingCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: code.code,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '请扫描二维码完成绑定',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '绑定码',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            code.code,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
