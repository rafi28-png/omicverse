import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum EvidenceTier {
  tier1('Tier 1', 'Strong evidence', kTier1),
  tier2('Tier 2', 'Moderate evidence', kTier2),
  tier3('Tier 3', 'Limited evidence', kTier3),
  tier4('Tier 4', 'Prediction only', kTier4);

  final String label;
  final String description;
  final Color color;
  const EvidenceTier(this.label, this.description, this.color);
}

class EvidenceBadge extends StatelessWidget {
  final EvidenceTier tier;
  final bool showTooltip;

  const EvidenceBadge({
    super.key,
    required this.tier,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tier.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        tier.label.toUpperCase(),
        style: tsBadge().copyWith(color: tier.color),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: tier.description,
        child: badge,
      );
    }
    return badge;
  }
}
