import 'package:flutter/material.dart';

/// Accessibility utilities for WCAG AA compliance and reduced motion.
class A11y {
  /// Check if reduced motion is preferred (system or app toggle)
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get appropriate animation duration (respects reduced motion)
  static Duration animDuration(BuildContext context, Duration normal) {
    return prefersReducedMotion(context) ? Duration.zero : normal;
  }

  /// Get appropriate animation curve (respects reduced motion)
  static Curve animCurve(BuildContext context, Curve normal) {
    return prefersReducedMotion(context) ? Curves.linear : normal;
  }

  /// Semantic label helper for screen readers
  static String moduleLabel(String moduleName, {String? value}) {
    if (value != null) return '$moduleName: $value';
    return moduleName;
  }

  /// Ensure minimum touch target size (48x48 per WCAG)
  static const double minTouchTarget = 48.0;
}
