import 'package:flutter/material.dart';
import 'package:mindisle_client/features/user/presentation/profile/profile_state.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class ProfileAvatarSelector extends StatelessWidget {
  const ProfileAvatarSelector({
    super.key,
    required this.state,
    this.onTapChangeAvatar,
  });

  static const _avatarSize = 132.0;

  final ProfileState state;
  final VoidCallback? onTapChangeAvatar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatar = SizedBox(
      width: _avatarSize,
      height: _avatarSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircleAvatar(
            radius: _avatarSize / 2,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: state.avatarBytes == null
                ? null
                : MemoryImage(state.avatarBytes!),
            child: state.avatarBytes == null
                ? Icon(
                    Icons.person_outline,
                    size: 42,
                    color: colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          if (state.isUploadingAvatar)
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
    );

    if (onTapChangeAvatar == null) {
      return Center(child: avatar);
    }

    return Center(
      child: InkWell(
        onTap: state.isUploadingAvatar ? null : onTapChangeAvatar,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}
