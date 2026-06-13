import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Error boundary widget that catches errors in child widget tree
/// and displays a friendly fallback UI instead of crashing.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String moduleName;

  const ErrorBoundary({super.key, required this.child, required this.moduleName});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hasError = false;
    _errorMessage = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, color: kNeonRed.withValues(alpha: 0.6), size: 48),
            const SizedBox(height: 16),
            Text('${widget.moduleName} encountered an error',
              style: tsTitle(kTextSecondary).copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error',
              style: tsBody().copyWith(color: kTextMuted, fontSize: 12),
              textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Retry', style: tsBadge().copyWith(color: kNeonTeal)),
              onPressed: () => setState(() { _hasError = false; _errorMessage = null; }),
            ),
          ]),
        ),
      );
    }

    return widget.child;
  }
}
