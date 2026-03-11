import 'package:app_ui/src/widget/auth/auth_utils.dart';
import 'package:app_ui/src/widget/login_submit_button.dart';
import 'package:flutter/material.dart';

class AuthPasswordStepView extends StatelessWidget {
  const AuthPasswordStepView({
    required this.title,
    required this.description,
    required this.labelText,
    required this.hintText,
    required this.inlineError,
    required this.isSubmitting,
    required this.onPasswordChanged,
    required this.onSubmit,
    super.key,
    this.onForgotPassword,
    this.forgotPasswordLabel = '忘记密码？',
  });

  final String title;
  final String description;
  final String labelText;
  final String hintText;
  final String? inlineError;
  final bool isSubmitting;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onForgotPassword;
  final String forgotPasswordLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final border = buildAuthOutlineBorder(context);
    final errorBorder = buildAuthOutlineBorder(context, isError: true);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: <Widget>[
          const Spacer(flex: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: TextField(
                    autofocus: true,
                    obscureText: true,
                    enabled: !isSubmitting,
                    onChanged: onPasswordChanged,
                    onSubmitted: (_) => onSubmit(),
                    maxLength: 20,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                    decoration: InputDecoration(
                      labelText: labelText,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: hintText,
                      counterText: '',
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
                      inlineError ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ),
                ),
                if (onForgotPassword != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                      onPressed: isSubmitting ? null : onForgotPassword,
                      child: Text(
                        forgotPasswordLabel,
                        style: Theme.of(context).textTheme.bodySmall,
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
                onPressed: onSubmit,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
