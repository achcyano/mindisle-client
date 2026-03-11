import 'package:flutter/material.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    required this.isSubmitting,
    required this.onPressed,
    super.key,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: isSubmitting ? null : onPressed,
        elevation: 3,
        highlightElevation: 5,
        hoverElevation: 4,
        focusElevation: 4,
        disabledElevation: 1,
        child: isSubmitting
            ? SizedBox(
                width: 22,
                height: 22,
                child: FittedBox(
                  child: CircularProgressIndicatorM3E(
                    activeColor: colorScheme.onPrimary,
                    trackColor: colorScheme.onPrimary.withValues(alpha: 0.24),
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward),
      ),
    );
  }
}
