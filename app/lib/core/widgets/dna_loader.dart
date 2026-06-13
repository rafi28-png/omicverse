import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DnaLoader extends StatefulWidget {
  final double size;
  final String? message;
  const DnaLoader({super.key, this.size = 48, this.message});

  @override
  State<DnaLoader> createState() => _DnaLoaderState();
}

class _DnaLoaderState extends State<DnaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check reduced motion
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: reduceMotion
              ? Icon(Icons.hourglass_empty, color: kNeonTeal, size: widget.size * 0.6)
              : AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _DnaPainter(_ctrl.value),
                    );
                  },
                ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 13,
              color: kTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _DnaPainter extends CustomPainter {
  final double progress;
  _DnaPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = kNeonTeal
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paint2 = Paint()
      ..color = kNeonPurple
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.35;

    final angle = progress * 2 * 3.14159;
    for (int i = 0; i < 6; i++) {
      final a = angle + i * 3.14159 / 3;
      final x1 = cx + r * _cos(a);
      final y1 = cy + r * 0.4 * _sin(a) + (i - 2.5) * size.height / 7;
      final x2 = cx - r * _cos(a);
      final y2 = y1;
      canvas.drawCircle(Offset(x1, y1), 3, paint1..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x2, y2), 3, paint2..style = PaintingStyle.fill);
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()..color = kBorder..strokeWidth = 1,
      );
    }
  }

  double _cos(double a) => a.cos();
  double _sin(double a) => a.sin();

  @override
  bool shouldRepaint(covariant _DnaPainter old) => old.progress != progress;
}

extension _MathExt on double {
  double cos() => _cosVal(this);
  double sin() => _sinVal(this);
}

double _cosVal(double v) {
  // Simple Taylor series approximation
  final x = v % (2 * 3.14159265);
  return 1 - (x*x)/2 + (x*x*x*x)/24 - (x*x*x*x*x*x)/720;
}

double _sinVal(double v) {
  final x = v % (2 * 3.14159265);
  return x - (x*x*x)/6 + (x*x*x*x*x)/120 - (x*x*x*x*x*x*x)/5040;
}
