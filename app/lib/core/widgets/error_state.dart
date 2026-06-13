import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'neon_button.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonRed.withValues(alpha: 0.1),
                border: Border.all(color: kNeonRed.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: kNeonRed, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: tsBody(),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              NeonButton(
                label: 'Retry',
                icon: Icons.refresh,
                color: kNeonTeal,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
