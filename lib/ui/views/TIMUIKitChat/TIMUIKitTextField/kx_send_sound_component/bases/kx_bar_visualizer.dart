import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'visualizer_mixin.dart';

/// **BarVisualizer**
///
/// Symmetric equalizer bars that scale with amplitude.
class KxBarVisualizer extends StatefulWidget {
  final bool isRecording;
  final double amplitude;
  final Color? color;
  final double height;
  final int barCount;
  final double barWidth;
  final double barSpacing;
  final Duration animationDuration;

  const KxBarVisualizer({
    super.key,
    required this.isRecording,
    required this.amplitude,
    this.color,
    this.height = 48.0,
    this.barCount = 15,
    this.barWidth = 4.0,
    this.barSpacing = 6.0,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<KxBarVisualizer> createState() => _KxBarVisualizerState();
}

class _KxBarVisualizerState extends State<KxBarVisualizer>
    with TickerProviderStateMixin, VisualizerMixin {
  @override
  bool get isRecording => widget.isRecording;

  @override
  double get rawAmplitude => widget.amplitude;

  @override
  Duration get animationDuration => widget.animationDuration;

  @override
  void initState() {
    super.initState();
    initVisualizer();
  }

  @override
  void didUpdateWidget(KxBarVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateRecordingState(oldWidget.isRecording);
    updateAmplitude(oldWidget.amplitude);
  }

  @override
  void dispose() {
    disposeVisualizer();
    super.dispose();
  }

  @override
  void onAmplitudeUpdated() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Colors.white;

    return FadeTransition(
      opacity: revealAnimation,
      child: Container(
        height: widget.height,
        width: double.infinity,
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: revealAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(
                (widget.barCount * widget.barWidth) +
                    ((widget.barCount - 1) * widget.barSpacing),
                widget.height,
              ),
              painter: _BarPainter(
                phase: phase,
                amplitude: currentAmplitude,
                revealProgress: revealAnimation.value,
                color: themeColor,
                barCount: widget.barCount,
                barWidth: widget.barWidth,
                barSpacing: widget.barSpacing,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final double revealProgress;
  final Color color;
  final int barCount;
  final double barWidth;
  final double barSpacing;

  _BarPainter({
    required this.phase,
    required this.amplitude,
    required this.revealProgress,
    required this.color,
    required this.barCount,
    required this.barWidth,
    required this.barSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (revealProgress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    final int halfCount = barCount ~/ 2;

    for (int i = 0; i < barCount; i++) {
      // Calculate distance from center (0 = center, 1 = edge)
      final double distanceFromCenter = (i - halfCount).abs() / halfCount;

      // Calculate individual bar amplitude based on sine wave and distance
      // Add slight phase offset for each bar to create a wave effect
      final double barPhase = phase + (i * 0.5);
      final double activeMultiplier = math.max(
        0.2,
        math.sin(barPhase) * 0.5 + 0.5,
      );

      // Bell curve shaping - taller in the middle
      final double bellCurve =
          1.0 - (distanceFromCenter * distanceFromCenter * 0.6);

      // Final height incorporates global amplitude, individual active wave, and reveal scale
      double barHeight = size.height *
          bellCurve *
          revealProgress *
          (0.1 + (amplitude * activeMultiplier * 0.9));

      // Minimum height
      if (barHeight < 4.0) barHeight = 4.0 * revealProgress;

      final double x = i * (barWidth + barSpacing);
      final Rect barRect = Rect.fromCenter(
        center: Offset(x + barWidth / 2, centerY),
        width: barWidth,
        height: barHeight,
      );

      final RRect roundedRect = RRect.fromRectAndRadius(
        barRect,
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(roundedRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.color != color;
  }
}
