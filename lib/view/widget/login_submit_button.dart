import 'package:flutter/material.dart';

class LoginSubmitButton extends StatefulWidget {
  const LoginSubmitButton({
    required this.isSubmitting,
    required this.onPressed,
    super.key,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  State<LoginSubmitButton> createState() => _LoginSubmitButtonState();
}

class _LoginSubmitButtonState extends State<LoginSubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSubmit = !widget.isSubmitting;

    final backgroundColor = colorScheme.primary;
    final foregroundColor = colorScheme.onPrimary;

    return SizedBox(
      width: 56,
      height: 56,
      child: Semantics(
        button: true,
        enabled: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: () {
            if (!canSubmit) return;
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _pressed ? 0.10 : 0.14),
                    blurRadius: _pressed ? 2.2 : 4.0,
                    offset: Offset(0, _pressed ? 1 : 2),
                  ),
                ],
              ),
              child: Center(
                child: widget.isSubmitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_rounded,
                        color: foregroundColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }
}
