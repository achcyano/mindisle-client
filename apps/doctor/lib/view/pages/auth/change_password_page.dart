import 'package:app_core/app_core.dart';
import 'package:app_ui/app_ui.dart';
import 'package:doctor/features/doctor_auth/presentation/providers/doctor_auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorChangePasswordPage extends ConsumerWidget {
  const DoctorChangePasswordPage({super.key});

  static final route = AppRoute<void>(
    path: '/password/change',
    builder: (_) => const DoctorChangePasswordPage(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChangePasswordFormPage(
      pageTitle: '修改密码',
      headline: '请输入旧密码和新密码',
      description: '新密码长度为 6 到 20 位。',
      oldPasswordLabel: '旧密码',
      oldPasswordHint: '请输入旧密码',
      newPasswordLabel: '新密码',
      newPasswordHint: '请输入新密码',
      submitLabel: '确认修改',
      submittingLabel: '提交中...',
      confirmTitle: '确认修改密码',
      confirmContent: '修改后请使用新密码重新登录。',
      confirmActionLabel: '继续',
      emptyOldPasswordError: '请输入旧密码',
      shortPasswordError: '新密码至少 6 位',
      longPasswordError: '新密码不能超过 20 位',
      samePasswordError: '新旧密码不能相同',
      onSubmit: (submitContext, oldPassword, newPassword) async {
        final result = await ref
            .read(doctorChangePasswordUseCaseProvider)
            .execute(oldPassword: oldPassword, newPassword: newPassword);

        switch (result) {
          case Success<void>():
            if (!submitContext.mounted) return null;
            showAuthSnackBar(submitContext, '密码修改成功', useCustomKeypad: false);
            Navigator.of(submitContext).pop();
            return null;
          case Failure<void>(error: final error):
            return error.message;
        }
      },
    );
  }
}
