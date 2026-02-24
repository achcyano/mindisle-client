import 'package:flutter/material.dart';

class StartupNetworkErrorCard extends StatelessWidget {
  const StartupNetworkErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.isRetrying = false,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: colorScheme.errorContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isRetrying ? null : onRetry,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.onErrorContainer.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox.square(
                dimension: 24,
                child: isRetrying
                    ? FittedBox(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onErrorContainer,
                          ),
                        ),
                      )
                    : Icon(Icons.refresh, color: colorScheme.onErrorContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
