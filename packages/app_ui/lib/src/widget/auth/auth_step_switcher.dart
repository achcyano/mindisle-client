import 'package:flutter/material.dart';

class AuthStepSwitcher extends StatelessWidget {
  const AuthStepSwitcher({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 280),
    this.beginOffset = const Offset(0.16, 0),
  });

  final Widget child;
  final Duration duration;
  final Offset beginOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: child,
    );
  }
}
