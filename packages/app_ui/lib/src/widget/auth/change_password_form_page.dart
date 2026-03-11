import 'package:app_ui/src/widget/app_dialog.dart';
import 'package:flutter/material.dart';

typedef ChangePasswordSubmit = Future<String?> Function(
  BuildContext context,
  String oldPassword,
  String newPassword,
);

class ChangePasswordFormPage extends StatefulWidget {
  const ChangePasswordFormPage({
    super.key,
    required this.pageTitle,
    required this.headline,
    required this.description,
    required this.oldPasswordLabel,
    required this.oldPasswordHint,
    required this.newPasswordLabel,
    required this.newPasswordHint,
    required this.submitLabel,
    required this.submittingLabel,
    required this.confirmTitle,
    required this.confirmContent,
    required this.confirmActionLabel,
    required this.emptyOldPasswordError,
    required this.shortPasswordError,
    required this.longPasswordError,
    required this.samePasswordError,
    required this.onSubmit,
    this.minPasswordLength = 6,
    this.maxPasswordLength = 20,
  });

  final String pageTitle;
  final String headline;
  final String description;
  final String oldPasswordLabel;
  final String oldPasswordHint;
  final String newPasswordLabel;
  final String newPasswordHint;
  final String submitLabel;
  final String submittingLabel;
  final String confirmTitle;
  final String confirmContent;
  final String confirmActionLabel;
  final String emptyOldPasswordError;
  final String shortPasswordError;
  final String longPasswordError;
  final String samePasswordError;
  final int minPasswordLength;
  final int maxPasswordLength;
  final ChangePasswordSubmit onSubmit;

  @override
  State<ChangePasswordFormPage> createState() => _ChangePasswordFormPageState();
}

class _ChangePasswordFormPageState extends State<ChangePasswordFormPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          children: <Widget>[
            Text(widget.headline, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _oldPasswordController,
              enabled: !_isSubmitting,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: widget.oldPasswordLabel,
                hintText: widget.oldPasswordHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              enabled: !_isSubmitting,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
              decoration: InputDecoration(
                labelText: widget.newPasswordLabel,
                hintText: widget.newPasswordHint,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _inlineError ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset),
              label: Text(
                _isSubmitting ? widget.submittingLabel : widget.submitLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (oldPassword.isEmpty) {
      setState(() => _inlineError = widget.emptyOldPasswordError);
      return;
    }
    if (newPassword.length < widget.minPasswordLength) {
      setState(() => _inlineError = widget.shortPasswordError);
      return;
    }
    if (newPassword.length > widget.maxPasswordLength) {
      setState(() => _inlineError = widget.longPasswordError);
      return;
    }
    if (oldPassword == newPassword) {
      setState(() => _inlineError = widget.samePasswordError);
      return;
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => buildAppAlertDialog(
        title: Text(widget.confirmTitle),
        content: Text(widget.confirmContent),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(widget.confirmActionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final errorMessage = await widget.onSubmit(
      context,
      oldPassword,
      newPassword,
    );
    if (!mounted) return;

    if (errorMessage == null || errorMessage.isEmpty) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = false;
      _inlineError = errorMessage;
    });
  }
}
