import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class DoctorSectionCard extends StatelessWidget {
  const DoctorSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.loading = false,
    this.errorMessage,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    return SettingsGroup(
      title: title,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 8, runSpacing: 8, children: actions),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
