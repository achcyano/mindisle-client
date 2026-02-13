import 'package:flutter/material.dart';
import 'package:mindisle_client/view/widget/login_submit_button.dart';
import 'package:mindisle_client/view/widget/number_keypad.dart';

class OtpStepView extends StatelessWidget {
  const OtpStepView({
    required this.phoneDigits,
    required this.otpDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmit,
    super.key,
  });

  final String phoneDigits;
  final String otpDigits;
  final String? inlineError;
  final bool isSubmitting;
  final bool canSubmit;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmit;

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
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '验证码已发送至 ${_formatPhone(phoneDigits)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    _OtpCell(value: i < otpDigits.length ? otpDigits[i] : ''),
                    if (i != 5) const SizedBox(width: 8),
                  ],
                ],
              ),
              if (inlineError != null) ...[
                const SizedBox(height: 10),
                Text(
                  inlineError!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Spacer(flex: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerRight,
            child: LoginSubmitButton(
              isSubmitting: isSubmitting,
              enabled: canSubmit,
              onPressed: onSubmit,
            ),
          ),
        ),
        const SizedBox(height: 10),
        NumberKeypad(
          onDigitPressed: onDigitPressed,
          onBackspacePressed: onBackspacePressed,
          enabled: !isSubmitting,
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
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
