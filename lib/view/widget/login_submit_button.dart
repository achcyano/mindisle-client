import 'package:flutter/material.dart';

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
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward),
      ),
    );
  }
}
