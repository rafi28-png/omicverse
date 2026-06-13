import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class ModuleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isDemoMode;

  const ModuleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.gradientColors = kGradGenome,
    this.icon = Icons.science_outlined,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: gradientColors),
              boxShadow: [glowShadow(gradientColors.first)],
            ),
            child: Icon(icon, color: kVoid, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tsTitle(kTextPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: tsSubtitle()),
              ],
            ),
          ),
          if (isDemoMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kNeonAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kNeonAmber.withValues(alpha: 0.4)),
              ),
              child: Text('DEMO', style: tsBadge().copyWith(color: kNeonAmber)),
            ),
        ],
      ),
    );
  }
}
