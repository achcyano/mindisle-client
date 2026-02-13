import 'package:flutter/material.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    required this.isSubmitting,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final bool isSubmitting;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: enabled && !isSubmitting ? onPressed : null,
        shape: const CircleBorder(),
        elevation: 1.2,
        focusElevation: 1.6,
        hoverElevation: 1.6,
        highlightElevation: 2.0,
        disabledElevation: 0.6,
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Icon(Icons.arrow_forward_rounded),
      ),
    );
  }
}
