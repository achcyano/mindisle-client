import 'package:doctor/features/doctor_binding/presentation/binding/doctor_binding_controller.dart';
import 'package:doctor/view/pages/home/widgets/doctor_section_card.dart';
import 'package:doctor/view/route/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorBindingsPage extends ConsumerStatefulWidget {
  const DoctorBindingsPage({super.key});

  static final route = AppRoute<void>(
    path: '/bindings',
    builder: (_) => const DoctorBindingsPage(),
  );

  @override
  ConsumerState<DoctorBindingsPage> createState() => _DoctorBindingsPageState();
}

class _DoctorBindingsPageState extends ConsumerState<DoctorBindingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorBindingControllerProvider.notifier).refreshHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bindingState = ref.watch(doctorBindingControllerProvider);
    final latestCode = bindingState.data.latestCode?.code ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('绑定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DoctorSectionCard(
            title: '绑定码与绑定历史',
            subtitle:
                'latestCode=$latestCode, history=${bindingState.data.history.length}',
            errorMessage: bindingState.errorMessage,
            loading: bindingState.isLoading,
            actions: <Widget>[
              FilledButton.tonal(
                onPressed: () => _onShowMessage(
                  ref
                      .read(doctorBindingControllerProvider.notifier)
                      .createCode(),
                ),
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
