import 'package:flutter/material.dart';
import 'package:mindisle_client/features/auth/presentation/login/login_flow_state.dart';
import 'package:mindisle_client/view/widget/login_submit_button.dart';

class PasswordStepView extends StatelessWidget {
  const PasswordStepView({
    required this.mode,
    required this.phoneDigits,
    required this.inlineError,
    required this.isSubmitting,
    required this.onPasswordChanged,
    required this.onSubmit,
    super.key,
  });

  final LoginFlowMode mode;
  final String phoneDigits;
  final String? inlineError;
  final bool isSubmitting;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isRegister = mode == LoginFlowMode.register;
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const Spacer(flex: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  isRegister ? '设置登录密码' : '输入登录密码',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isRegister
                      ? '为 ${_formatPhone(phoneDigits)} 设置密码（至少 6 位）'
                      : '请输入 ${_formatPhone(phoneDigits)} 的密码',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w300,
                    fontSize: 13,
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
                    maxLength: 20,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          fontSize: 17,
                        ),
                    decoration: InputDecoration(
                      labelText: '密码',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: '请输入密码',
                      counterText: '',
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
                      inlineError ?? '',
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

  String _formatPhone(String value) {
    if (value.length != 11) return value;
    return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
  }
}
