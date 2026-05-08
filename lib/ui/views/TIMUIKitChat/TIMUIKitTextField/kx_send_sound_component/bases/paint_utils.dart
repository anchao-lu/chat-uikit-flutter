import 'package:flutter/material.dart';

/// Common painting utilities shared between visualizers.
class PaintUtils {
  PaintUtils._();

  /// Creates a stroke paint with optional glow effect.
  static Paint strokePaint({
    required Color color,
    required double strokeWidth,
    double alpha = 1.0,
  }) {
    return Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
  }

  /// Creates a glow paint for the main wave/line effect.
  static Paint glowPaint({
    required Color color,
    required double strokeWidth,
    required double amplitude,
    double blurRadius = 5.0,
  }) {
    return Paint()
      ..color = color.withValues(alpha: 0.35 * amplitude)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
  }

  /// Creates a filled paint with optional glow.
  static Paint filledPaint({required Color color, double alpha = 1.0}) {
    return Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
  }

  /// Creates a radial gradient shader for circle-based effects.
  static Paint radialGlowPaint({
    required Color color,
    required Offset center,
    required double radius,
    double alpha = 0.5,
  }) {
    return Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
  }
}