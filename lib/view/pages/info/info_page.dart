import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/pages/info/profile_basic_info_form_card.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class InfoPage extends ConsumerStatefulWidget {
  const InfoPage({super.key});

  static final route = AppRoute<void>(
    path: '/info',
    builder: (_) => const InfoPage(),
  );

  @override
  ConsumerState<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends ConsumerState<InfoPage> {
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      if (message == _lastErrorMessage) return;
      _lastErrorMessage = message;
      _showSnack(message);
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('编辑资料')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: _buildContent(state: state, controller: controller),
        ),
      ),
    );
  }

  Widget _buildContent({
    required ProfileState state,
    required ProfileController controller,
  }) {
    if (state.isLoading && state.profile == null) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicatorM3E()),
      );
    }

    if (state.profile == null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: FilledButton(
            onPressed: () => controller.initialize(refresh: true),
            child: const Text('重试'),
          ),
        ),
      );
    }

    return ProfileBasicInfoFormCard(
      data: ProfileBasicInfoFormData.fromState(state),
      actions: ProfileBasicInfoFormActions.fromController(
        controller: controller,
        onSavePressed: state.isSaving ? null : () => _saveProfile(controller),
      ),
    );
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile(ProfileController controller) async {
    final message = await controller.saveProfile();
    if (!mounted || message == null || message.isEmpty) return;
    _showSnack(message);
  }
}
