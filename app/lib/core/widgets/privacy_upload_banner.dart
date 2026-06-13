import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class PrivacyUploadBanner extends StatelessWidget {
  const PrivacyUploadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kNeonTeal.withValues(alpha: 0.08),
        border: Border.all(color: kNeonTeal.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outlined, color: kNeonTeal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your files are processed locally and never leave this device. '
              'Only computed results are saved.',
              style: tsBody().copyWith(fontSize: 12, color: kTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
