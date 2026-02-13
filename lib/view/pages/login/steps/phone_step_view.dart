import 'package:flutter/material.dart';
import 'package:mindisle_client/view/widget/login_submit_button.dart';
import 'package:mindisle_client/view/widget/number_keypad.dart';

class PhoneStepView extends StatefulWidget {
  const PhoneStepView({
    required this.phoneDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmit,
    super.key,
  });

  final String phoneDigits;
  final String? inlineError;
  final bool isSubmitting;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmit;

  @override
  State<PhoneStepView> createState() => _PhoneStepViewState();
}

class _PhoneStepViewState extends State<PhoneStepView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatPhone(widget.phoneDigits));
  }

  @override
  void didUpdateWidget(covariant PhoneStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneDigits == widget.phoneDigits) return;

    final text = _formatPhone(widget.phoneDigits);
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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: colorScheme.primary,
        width: 1.2,
      ),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: colorScheme.error,
        width: 1.2,
      ),
    );

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
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '请确认手机号码输入正确。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w300,
                  fontSize: 13
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46 ,
                child: TextField(
                  controller: _controller,
                  readOnly: true,
                  keyboardType: TextInputType.none,
                  showCursor: true,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    fontSize: 17
                  ),
                  decoration: InputDecoration(
                    labelText: '手机号码',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    filled: false,
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

  String _formatPhone(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 3) return value;
    if (value.length <= 7) {
      return '${value.substring(0, 3)} ${value.substring(3)}';
    }
    return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
  }
}
