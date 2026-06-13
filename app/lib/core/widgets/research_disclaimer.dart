import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class ResearchDisclaimer extends StatelessWidget {
  final String? customText;
  const ResearchDisclaimer({super.key, this.customText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kNeonAmber.withValues(alpha: 0.08),
        border: Border.all(color: kNeonAmber.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: kNeonAmber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              customText ??
                  'For research and education only. Not for clinical diagnosis, '
                  'treatment, or medical decision-making. Consult a qualified '
                  'professional for any health-related decision.',
              style: tsBody().copyWith(fontSize: 12, color: kTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
