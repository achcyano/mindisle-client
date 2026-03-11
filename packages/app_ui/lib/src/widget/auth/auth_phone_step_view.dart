import 'package:app_ui/src/widget/auth/auth_utils.dart';
import 'package:app_ui/src/widget/login_submit_button.dart';
import 'package:app_ui/src/widget/number_keypad.dart';
import 'package:flutter/material.dart';

class AuthPhoneStepView extends StatefulWidget {
  const AuthPhoneStepView({
    required this.phoneDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmit,
    super.key,
    this.title = '输入手机号',
    this.description = '请确认手机号输入正确。',
    this.labelText = '手机号',
  });

  final String phoneDigits;
  final String? inlineError;
  final bool isSubmitting;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmit;
  final String title;
  final String description;
  final String labelText;

  @override
  State<AuthPhoneStepView> createState() => _AuthPhoneStepViewState();
}

class _AuthPhoneStepViewState extends State<AuthPhoneStepView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatAuthPhone(widget.phoneDigits),
    );
  }

  @override
  void didUpdateWidget(covariant AuthPhoneStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneDigits == widget.phoneDigits) return;

    final text = formatAuthPhone(widget.phoneDigits);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final border = buildAuthOutlineBorder(context);
    final errorBorder = buildAuthOutlineBorder(context, isError: true);

    return Column(
      children: <Widget>[
        const Spacer(flex: 4),
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
                widget.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: TextField(
                  controller: _controller,
                  readOnly: true,
                  keyboardType: TextInputType.none,
                  showCursor: true,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                    disabledBorder: border,
                    errorBorder: errorBorder,
                    focusedErrorBorder: errorBorder,
                  ),
                ),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerRight,
            child: LoginSubmitButton(
              isSubmitting: widget.isSubmitting,
              onPressed: widget.onSubmit,
            ),
          ),
        ),
        const SizedBox(height: 10),
        NumberKeypad(
          onDigitPressed: widget.onDigitPressed,
          onBackspacePressed: widget.onBackspacePressed,
          enabled: !widget.isSubmitting,
        ),
      ],
    );
  }
}
