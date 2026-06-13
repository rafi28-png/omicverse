import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = kNeonTeal,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: kBorder, width: 1),
          boxShadow: [
            glowShadow(glowColor),
            depthShadow(),
          ],
        ),
        child: child,
      ),
    );
  }
}
