import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Abstract base mixin for all visualizer widgets.
///
/// Handles common logic:
/// - Exponential smoothing low-pass filter for amplitude jitter
/// - Reveal/fade animation for isRecording toggle
/// - Infinite phase animation controller
mixin VisualizerMixin<T extends StatefulWidget> on TickerProviderStateMixin<T> {
  late AnimationController phaseController;
  late AnimationController revealController;
  late Animation<double> revealAnimation;

  double currentAmplitude = 0.0;
  double _targetAmplitude = 0.0;

  /// Override to get current widget props.
  bool get isRecording;
  double get rawAmplitude;
  Duration get animationDuration;

  /// Smoothing factor (0~1). Higher = more responsive but jittery.
  double get smoothingFactor => 0.15;

  /// Noise floor threshold. Below this, amplitude is treated as silence.
  double get noiseThreshold => 0.08;

  /// Amplitude boost multiplier for making quiet speech visible.
  double get amplitudeBoost => 3.0;

  void initVisualizer() {
    phaseController = AnimationController(
      vsync: this,
      duration: animationDuration,
    )..repeat();

    revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    revealAnimation = CurvedAnimation(
      parent: revealController,
      curve: Curves.easeInOut,
    );

    if (isRecording) {
      revealController.value = 1.0;
    }

    // Sync the initial amplitude so _targetAmplitude is not stuck at 0.0
    // on the first render. Without this, currentAmplitude never rises above
    // 0 until the parent widget rebuilds and triggers didUpdateWidget.
    _syncAmplitude(rawAmplitude);

    phaseController.addListener(_onTick);
  }

  void _onTick() {
    final newAmplitude =
        currentAmplitude +
            (_targetAmplitude - currentAmplitude) * smoothingFactor;

    if (_targetAmplitude == 0.0 && newAmplitude < 0.005) {
      currentAmplitude = 0.0;
    } else {
      currentAmplitude = newAmplitude;
    }

    onAmplitudeUpdated();
  }

  /// Called on each tick after amplitude is updated.
  /// Subclasses should call setState() here.
  void onAmplitudeUpdated();

  void updateRecordingState(bool wasRecording) {
    if (isRecording != wasRecording) {
      if (isRecording) {
        revealController.forward();
      } else {
        revealController.reverse();
      }
    }
  }

  void updateAmplitude(double oldAmplitude) {
    if (rawAmplitude == oldAmplitude) return;
    _syncAmplitude(rawAmplitude);
  }

  /// Converts a raw amplitude value into a smoothed target amplitude,
  /// applying the noise floor threshold and boost multiplier.
  void _syncAmplitude(double value) {
    if (value <= noiseThreshold) {
      _targetAmplitude = 0.0;
    } else {
      final effectiveAmp =
          ((value - noiseThreshold) / (1.0 - noiseThreshold)) * amplitudeBoost;
      _targetAmplitude = effectiveAmp.clamp(0.0, 1.0);
    }
  }

  void disposeVisualizer() {
    phaseController.removeListener(_onTick);
    phaseController.dispose();
    revealController.dispose();
  }

  /// Current phase in radians (0 ~ 2π).
  double get phase => phaseController.value * 2 * math.pi;
}