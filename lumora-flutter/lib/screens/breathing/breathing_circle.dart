import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'breathing_technique.dart';

const double kCircleMin = 150.0;
const double kCircleMax = 260.0;

class BreathingCircle extends StatelessWidget {
  final double size; // diameter, between kCircleMin and kCircleMax
  final Color color;
  final String phaseLabel;
  final int countdown;
  final bool bigCountdown; // 4-7-8 hold uses 56px
  final double glowRadius; // for 4-7-8 hold glow
  final List<double> rippleScales; // for slow deep breathing ripples
  final BreathingPhaseType phaseType;

  const BreathingCircle({
    super.key,
    required this.size,
    required this.color,
    required this.phaseLabel,
    required this.countdown,
    this.bigCountdown = false,
    this.glowRadius = 0,
    this.rippleScales = const [],
    required this.phaseType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kCircleMax + 60,
      height: kCircleMax + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings (slow deep breathing)
          for (final scale in rippleScales)
            Opacity(
              opacity: (1.0 - scale).clamp(0.0, 0.3),
              child: SizedBox(
                width: size + scale * 80,
                height: size + scale * 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                ),
              ),
            ),

          // Main circle with optional glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow:
                  glowRadius > 0
                      ? [
                        BoxShadow(
                          color: const Color(0xFF5BB8D4).withValues(alpha: 0.4),
                          blurRadius: glowRadius,
                          spreadRadius: 4,
                        ),
                      ]
                      : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$countdown',
                  style: TextStyle(
                    fontSize: bigCountdown ? 56 : 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phaseLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Box-style square progress arc ─────────────────────────────────────────

class BoxProgressPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0 over full round (4 phases)
  final Color color;

  BoxProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final activePaint =
        Paint()
          ..color = color
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final inset = 16.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    // Draw faded full box
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );

    // Draw active progress portion along the box perimeter
    final perimeter = (rect.width + rect.height) * 2;
    final activeLength = progress * perimeter;

    _drawBoxProgress(canvas, rect, activeLength, activePaint);
  }

  void _drawBoxProgress(Canvas canvas, Rect rect, double length, Paint paint) {
    final segments = [
      // top: left→right
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      // right: top→bottom
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      // bottom: right→left
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
      // left: bottom→top
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.top),
    ];

    double remaining = length;
    for (int i = 0; i < segments.length; i += 2) {
      final from = segments[i];
      final to = segments[i + 1];
      final segLen = (to - from).distance;
      if (remaining <= 0) break;
      if (remaining >= segLen) {
        canvas.drawLine(from, to, paint);
        remaining -= segLen;
      } else {
        final t = remaining / segLen;
        canvas.drawLine(from, Offset.lerp(from, to, t)!, paint);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(BoxProgressPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Circular progress arc ─────────────────────────────────────────────────

class CircularProgressPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0 over full round
  final Color color;

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bgPaint =
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final arcPaint =
        Paint()
          ..color = color
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter old) =>
      old.progress != progress || old.color != color;
}
