import 'package:app_ui/src/widget/auth/auth_utils.dart';
import 'package:app_ui/src/widget/login_submit_button.dart';
import 'package:app_ui/src/widget/number_keypad.dart';
import 'package:flutter/material.dart';

class AuthOtpStepView extends StatefulWidget {
  const AuthOtpStepView({
    required this.phoneDigits,
    required this.otpDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmit,
    super.key,
    this.isSendingCode = false,
    this.resendCooldownSeconds = 0,
    this.onResendPressed,
    this.showSubmitButton = false,
    this.autoSubmitOnComplete = true,
    this.title = '输入验证码',
    this.descriptionBuilder,
    this.resendLabel = '重发验证码',
    this.codeLength = 6,
    this.useOuterSpacers = true,
  });

  final String phoneDigits;
  final String otpDigits;
  final String? inlineError;
  final bool isSubmitting;
  final bool isSendingCode;
  final int resendCooldownSeconds;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmit;
  final VoidCallback? onResendPressed;
  final bool showSubmitButton;
  final bool autoSubmitOnComplete;
  final String title;
  final String Function(String formattedPhone)? descriptionBuilder;
  final String resendLabel;
  final int codeLength;
  final bool useOuterSpacers;

  @override
  State<AuthOtpStepView> createState() => _AuthOtpStepViewState();
}

class _AuthOtpStepViewState extends State<AuthOtpStepView> {
  @override
  void didUpdateWidget(covariant AuthOtpStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justCompleted =
        oldWidget.otpDigits.length < widget.codeLength &&
        widget.otpDigits.length == widget.codeLength;
    if (!justCompleted || !widget.autoSubmitOnComplete) return;
    if (widget.isSubmitting || widget.isSendingCode) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onSubmit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final descriptionStyle = Theme.of(context).textTheme.bodySmall;
    final canResend =
        widget.onResendPressed != null &&
        widget.resendCooldownSeconds == 0 &&
        !widget.isSubmitting &&
        !widget.isSendingCode;
    final formattedPhone = formatAuthPhone(widget.phoneDigits);
    final description =
        widget.descriptionBuilder?.call(formattedPhone) ??
        '验证码已发送至 $formattedPhone';

    return Column(
      children: <Widget>[
        if (widget.useOuterSpacers) const Spacer(flex: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: <Widget>[
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: descriptionStyle?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (
                    var index = 0;
                    index < widget.codeLength;
                    index++
                  ) ...<Widget>[
                    _AuthOtpCell(
                      value: index < widget.otpDigits.length
                          ? widget.otpDigits[index]
                          : '',
                    ),
                    if (index != widget.codeLength - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              if (widget.onResendPressed != null) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    TextButton(
                      style: TextButton.styleFrom(textStyle: descriptionStyle),
                      onPressed: canResend ? widget.onResendPressed : null,
                      child: Text(
                        canResend
                            ? widget.resendLabel
                            : '${widget.resendLabel}(${widget.resendCooldownSeconds}s)',
                        style: descriptionStyle,
                      ),
                    ),
                    if (widget.isSendingCode)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ] else
                const SizedBox(height: 6),
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.inlineError ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: descriptionStyle?.copyWith(color: colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.useOuterSpacers) const Spacer(flex: 3),
        if (widget.showSubmitButton) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: LoginSubmitButton(
                isSubmitting: widget.isSubmitting || widget.isSendingCode,
                onPressed: widget.onSubmit,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 10),
        NumberKeypad(
          onDigitPressed: widget.onDigitPressed,
          onBackspacePressed: widget.onBackspacePressed,
          enabled: !widget.isSubmitting && !widget.isSendingCode,
        ),
      ],
    );
  }
}

class _AuthOtpCell extends StatelessWidget {
  const _AuthOtpCell({required this.value});

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
        border: Border.all(color: colorScheme.primary, width: 1.2),
      ),
      child: Text(value, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
