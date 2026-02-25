import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindisle_client/features/user/domain/entities/user_profile.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_controller.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  static final route = AppRoute<void>(
    path: '/home/profile',
    builder: (_) => const ProfilePage(),
  );

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  static const _avatarBaseSize = 132.0;
  static const _expandTriggerDistance = 10.0;
  static const _collapseTriggerDistance = 12.0;
  static const _maxOverscrollDistance = 96.0;

  String? _lastErrorMessage;
  late final AnimationController _avatarController;
  bool _avatarFullWidthLocked = false;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (!mounted) return;
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message.isEmpty) return;
      if (message == _lastErrorMessage) return;
      _lastErrorMessage = message;

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      body: _buildBody(
        context: context,
        state: state,
        controller: controller,
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ProfileState state,
    required ProfileController controller,
  }) {
    if (state.isLoading && state.profile == null) {
      return const Center(child: CircularProgressIndicatorM3E());
    }
    if (state.profile == null) {
      return Center(
        child: FilledButton(
          onPressed: () => controller.initialize(refresh: true),
          child: const Text('Retry'),
        ),
      );
    }

    final profile = state.profile!;
    final formIdentity = [
      profile.userId,
      profile.fullName ?? '',
      profile.gender.name,
      profile.birthDate ?? '',
      profile.heightCm?.toString() ?? '',
      profile.weightKg?.toString() ?? '',
      profile.waistCm?.toString() ?? '',
      profile.diseaseHistory.join('|'),
    ].join('#');

    final hasAvatar = state.avatarBytes != null && state.avatarBytes!.isNotEmpty;
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final baseAvatarTop = topInset + kToolbarHeight + 12;
    final headerBaseHeight = baseAvatarTop + _avatarBaseSize + 18;
    final maxStretchOverscroll = hasAvatar ? _maxOverscrollDistance : 0.0;
    final stretchProgress = hasAvatar ? _avatarController.value : 0.0;
    final hideAppBarTitle = hasAvatar && stretchProgress > 0.001;
    final avatarTop = hasAvatar
        ? lerpDouble(baseAvatarTop, 0, stretchProgress)!
        : baseAvatarTop;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!hasAvatar || maxStretchOverscroll <= 0) {
          if (_avatarController.value != 0 || _avatarFullWidthLocked) {
            _avatarFullWidthLocked = false;
            _avatarController.value = 0;
          }
          return false;
        }

        final metrics = notification.metrics;
        final overscrollDistance = metrics.pixels < metrics.minScrollExtent
            ? (metrics.minScrollExtent - metrics.pixels).clamp(
                0.0,
                maxStretchOverscroll,
              )
            : 0.0;

        if (!_avatarFullWidthLocked &&
            overscrollDistance >= _expandTriggerDistance) {
          _avatarFullWidthLocked = true;
          if (_avatarController.value < 1.0) {
            _avatarController.animateTo(1.0, curve: Curves.easeOutCubic);
          }
          return false;
        }

        if (_avatarFullWidthLocked &&
            metrics.pixels >
                metrics.minScrollExtent + _collapseTriggerDistance) {
          _avatarFullWidthLocked = false;
          if (_avatarController.value > 0.0) {
            _avatarController.animateTo(0.0, curve: Curves.easeOutCubic);
          }
          return false;
        }

        return false;
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _buildAvatarSelector(
              context: context,
              state: state,
              topOffset: avatarTop,
              stretchProgress: stretchProgress,
              onTapChangeAvatar: _showAvatarPickerSheet,
            ),
          ),
          CustomScrollView(
            physics: hasAvatar
                ? _AvatarStretchPhysics(
                    maxOverscroll: maxStretchOverscroll,
                    parent: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                  )
                : const ClampingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                centerTitle: true,
                forceMaterialTransparency: hasAvatar,
                backgroundColor: hasAvatar
                    ? Colors.transparent
                    : Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: hideAppBarTitle ? null : const Text('Profile'),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: headerBaseHeight),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Card(
                        child: Padding(
                          key: ValueKey(formIdentity),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Basic Info',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Name',
                                initialValue: state.fullName,
                                textInputAction: TextInputAction.next,
                                onChanged: controller.setFullName,
                              ),
                              const SizedBox(height: 10),
                              _buildGenderField(
                                value: state.gender,
                                onChanged: controller.setGender,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                label: 'Birth date (yyyy-MM-dd)',
                                initialValue: state.birthDate,
                                textInputAction: TextInputAction.next,
                                onChanged: controller.setBirthDate,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                label: 'Height (cm)',
                                initialValue: state.heightCm,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: controller.setHeightCm,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                label: 'Weight (kg)',
                                initialValue: state.weightKg,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: controller.setWeightKg,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                label: 'Waist (cm)',
                                initialValue: state.waistCm,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: controller.setWaistCm,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                label: 'Medical history (one per line)',
                                initialValue: state.diseaseHistoryInput,
                                minLines: 3,
                                maxLines: 6,
                                textInputAction: TextInputAction.newline,
                                onChanged: controller.setDiseaseHistoryInput,
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: state.isSaving
                                    ? null
                                    : () => _saveProfile(controller),
                                icon: state.isSaving
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: FittedBox(
                                          child: CircularProgressIndicatorM3E(),
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label:
                                    Text(state.isSaving ? 'Saving...' : 'Save'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSelector({
    required BuildContext context,
    required ProfileState state,
    required double topOffset,
    required double stretchProgress,
    required VoidCallback onTapChangeAvatar,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAvatar = state.avatarBytes != null && state.avatarBytes!.isNotEmpty;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final width = hasAvatar
        ? lerpDouble(_avatarBaseSize, screenWidth, stretchProgress)!
        : _avatarBaseSize;
    final height = hasAvatar
        ? lerpDouble(_avatarBaseSize, screenWidth, stretchProgress)!
        : _avatarBaseSize;
    final borderRadius = hasAvatar
        ? lerpDouble(_avatarBaseSize / 2, 0, stretchProgress)!
        : _avatarBaseSize / 2;
    final imageFit = stretchProgress >= 0.98 ? BoxFit.contain : BoxFit.cover;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: topOffset),
        child: InkWell(
          onTap: state.isUploadingAvatar ? null : onTapChangeAvatar,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: ColoredBox(
                    color: colorScheme.primaryContainer,
                    child: state.avatarBytes == null
                        ? Icon(
                            Icons.person_outline,
                            size: 42,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : Image.memory(
                            state.avatarBytes!,
                            fit: imageFit,
                          ),
                  ),
                ),
                if (state.isUploadingAvatar)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicatorM3E(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField({
    required UserGender value,
    required ValueChanged<UserGender> onChanged,
  }) {
    return DropdownButtonFormField<UserGender>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Gender'),
      items: const [
        DropdownMenuItem(value: UserGender.unknown, child: Text('Unknown')),
        DropdownMenuItem(value: UserGender.male, child: Text('Male')),
        DropdownMenuItem(value: UserGender.female, child: Text('Female')),
        DropdownMenuItem(value: UserGender.other, child: Text('Other')),
      ],
      onChanged: (next) {
        if (next == null) return;
        onChanged(next);
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int? minLines,
    int? maxLines,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      onChanged: onChanged,
    );
  }

  Future<void> _saveProfile(ProfileController controller) async {
    final message = await controller.saveProfile();
    if (!mounted || message == null || message.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAvatarPickerSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || source == null) return;
    final message = await ref
        .read(profileControllerProvider.notifier)
        .pickAndUploadAvatar(source);
    if (!mounted || message == null || message.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _AvatarStretchPhysics extends ScrollPhysics {
  const _AvatarStretchPhysics({
    required this.maxOverscroll,
    super.parent,
  });

  final double maxOverscroll;

  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 240,
    damping: 28,
  );

  @override
  _AvatarStretchPhysics applyTo(ScrollPhysics? ancestor) {
    return _AvatarStretchPhysics(
      maxOverscroll: maxOverscroll,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final minWithOverscroll = position.minScrollExtent - maxOverscroll;
    if (value < minWithOverscroll) {
      return value - minWithOverscroll;
    }
    if (value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    return 0;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.pixels < position.minScrollExtent) {
      return ScrollSpringSimulation(
        _spring,
        position.pixels,
        position.minScrollExtent,
        velocity,
        tolerance: toleranceFor(position),
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
