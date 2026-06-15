import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = kNeonTeal,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _hovering = false;

  bool get _disabled => widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.isLoading ? '${widget.label}, loading' : widget.label,
      child: MouseRegion(
        cursor: _disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) { if (!_disabled) setState(() => _hovering = true); },
        onExit:  (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: _disabled ? null : widget.onPressed,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _disabled ? 0.45 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _hovering ? widget.color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hovering ? widget.color : widget.color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: _hovering
                    ? [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 20)]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(widget.color),
                      ),
                    )
                  else if (widget.icon != null)
                    Icon(widget.icon, color: widget.color, size: 18),
                  if (widget.icon != null || widget.isLoading) const SizedBox(width: 10),
                  Text(
                    widget.label.toUpperCase(),
                    style: tsBadge().copyWith(color: widget.color, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
