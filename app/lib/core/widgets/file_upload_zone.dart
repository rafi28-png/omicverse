import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class FileUploadZone extends StatefulWidget {
  final String label;
  final String acceptedFormats;
  final VoidCallback? onTap;

  const FileUploadZone({
    super.key,
    this.label = 'Drop file here or tap to browse',
    this.acceptedFormats = '',
    this.onTap,
  });

  @override
  State<FileUploadZone> createState() => _FileUploadZoneState();
}

class _FileUploadZoneState extends State<FileUploadZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: _hovering ? kNeonTeal.withValues(alpha: 0.05) : kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering ? kNeonTeal.withValues(alpha: 0.5) : kBorder,
              width: _hovering ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: _hovering ? kNeonTeal : kTextMuted,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(widget.label, style: tsBody(), textAlign: TextAlign.center),
              if (widget.acceptedFormats.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Accepted: ${widget.acceptedFormats}',
                  style: tsLabel(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
