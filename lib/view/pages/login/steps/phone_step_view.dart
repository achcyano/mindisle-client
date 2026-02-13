import 'package:flutter/material.dart';
import 'package:mindisle_client/view/widget/login_submit_button.dart';
import 'package:mindisle_client/view/widget/number_keypad.dart';

class PhoneStepView extends StatelessWidget {
  const PhoneStepView({
    required this.phoneDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmit,
    super.key,
  });

  final String phoneDigits;
  final String? inlineError;
  final bool isSubmitting;
  final bool canSubmit;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                '输入手机号码',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '请确认手机号码输入正确。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.72),
                    ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: inlineError == null
                        ? Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.55)
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _formatPhone(phoneDigits),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                ),
              ),
              if (inlineError != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    inlineError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
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
    if (value.isEmpty) return '请输入手机号';
    if (value.length <= 3) return value;
    if (value.length <= 7) {
      return '${value.substring(0, 3)} ${value.substring(3)}';
    }
    return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
  }
}
