import 'package:flutter/material.dart';

class ConnectivityErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final Color? accentColor;

  const ConnectivityErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Elegant illustration-style Wifi Off icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Internet Connection',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'We couldn\'t connect to the server. Please check your network settings and try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.grey,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  }
}
