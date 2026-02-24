import 'package:flutter_riverpod/flutter_riverpod.dart';

final class StartupNetworkIssue {
  const StartupNetworkIssue({
    required this.message,
    required this.issueId,
    this.isNetwork = true,
    this.showSnackBar = false,
  });

  final String message;
  final int issueId;
  final bool isNetwork;
  final bool showSnackBar;
}

final startupNetworkIssueProvider = StateProvider<StartupNetworkIssue?>(
  (_) => null,
);
