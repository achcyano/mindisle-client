import 'package:flutter/material.dart';
import 'package:mindisle_client/view/widget/number_keypad.dart';

class OtpStepView extends StatefulWidget {
  const OtpStepView({
    required this.phoneDigits,
    required this.otpDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmit,
    super.key,
  });

  final String phoneDigits;
  final String otpDigits;
  final String? inlineError;
  final bool isSubmitting;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmit;

  @override
  State<OtpStepView> createState() => _OtpStepViewState();
}

class _OtpStepViewState extends State<OtpStepView> {
  @override
  void didUpdateWidget(covariant OtpStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justCompleted =
        oldWidget.otpDigits.length < 6 && widget.otpDigits.length == 6;
    if (justCompleted && !widget.isSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSubmit();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Spacer(flex: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                '输入验证码',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 19,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '验证码已发送至 ${_formatPhone(widget.phoneDigits)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w300,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    _OtpCell(
                      value: i < widget.otpDigits.length ? widget.otpDigits[i] : '',
                    ),
                    if (i != 5) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.inlineError ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
        const SizedBox(height: 10),
        NumberKeypad(
          onDigitPressed: widget.onDigitPressed,
          onBackspacePressed: widget.onBackspacePressed,
          enabled: !widget.isSubmitting,
        ),
      ],
    );
  }

  String _formatPhone(String value) {
    if (value.length != 11) return value;
    return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.primary,
          width: 1.2,
        ),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w300,
              fontSize: 17,
            ),
      ),
    );
  }
}
