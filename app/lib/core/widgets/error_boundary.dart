import 'package:flutter/material.dart';
import 'error_state.dart';

/// Error boundary widget that catches errors in child widget tree
/// and displays a friendly fallback UI instead of crashing.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String moduleName;

  const ErrorBoundary({super.key, required this.child, required this.moduleName});

  static _ErrorBoundaryState? _activeBoundary;

  /// Report a rendering or build error to the active ErrorBoundary.
  /// Returns true if the error was intercepted by a mounted boundary, false otherwise.
  static bool reportError(FlutterErrorDetails details) {
    final active = _activeBoundary;
    if (active != null && active.mounted) {
      active._showError(details.exception.toString());
      return true;
    }
    return false;
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  void _showError(String message) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = message;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ErrorBoundary._activeBoundary = this;
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    ErrorBoundary._activeBoundary = this;
  }

  @override
  void dispose() {
    if (ErrorBoundary._activeBoundary == this) {
      ErrorBoundary._activeBoundary = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep active boundary updated during build passes
    ErrorBoundary._activeBoundary = this;

    if (_hasError) {
      return ErrorState(
        message: '${widget.moduleName} encountered an error: ${_errorMessage ?? "Unknown error"}',
        onRetry: () {
          setState(() {
            _hasError = false;
            _errorMessage = null;
          });
        },
      );
    }

    return widget.child;
  }
}
