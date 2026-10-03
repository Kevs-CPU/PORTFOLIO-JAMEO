import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================
// ACTIVITY 3
// Live Performance Wave
//
// Animated vertical waveform bars.
// Higher network strength = taller bars.
// The waveform continuously moves while monitoring.
// ============================================================

class LivePerformanceWave extends StatefulWidget {
  final double strength;

  const LivePerformanceWave({
    super.key,
    required this.strength,
  });

  @override
  State<LivePerformanceWave> createState() =>
      _LivePerformanceWaveState();
}

class _LivePerformanceWaveState
    extends State<LivePerformanceWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1400,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: LivePerformanceWavePainter(
            progress: _controller.value,
            strength: widget.strength,
          ),
        );
      },
    );
  }
}

// ============================================================
// ACTIVITY 3
// Live Performance Wave Painter
// ============================================================

class LivePerformanceWavePainter
    extends CustomPainter {
  final double progress;
  final double strength;

  const LivePerformanceWavePainter({
    required this.progress,
    required this.strength,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // ----------------------------------------------------------
    // NORMALIZED NETWORK STRENGTH
    //
    // 0.0 = weakest
    // 1.0 = strongest
    // ----------------------------------------------------------

    final double normalizedStrength =
        strength.clamp(0.0, 1.0).toDouble();

    // ----------------------------------------------------------
    // WAVE COLOR
    // ----------------------------------------------------------

    final Color waveColor =
        const Color(0xFF45D483).withValues(
      alpha:
          0.55 +
              (normalizedStrength * 0.45),
    );

    final Color glowColor =
        const Color(0xFF45D483).withValues(
      alpha:
          0.08 +
              (normalizedStrength * 0.12),
    );

    // ----------------------------------------------------------
    // BAR SETTINGS
    // ----------------------------------------------------------

    const int barCount = 16;

    final double spacing =
        size.width / barCount;

    final double barWidth =
        spacing * 0.48;

    // ----------------------------------------------------------
    // HEIGHT
    //
    // Higher strength = taller waveform.
    // ----------------------------------------------------------

    final double maxBarHeight =
        size.height *
            (0.30 +
                (normalizedStrength * 0.62));

    final double minBarHeight =
        size.height * 0.10;

    final double centerY =
        size.height / 2;

    // ----------------------------------------------------------
    // ANIMATION SPEED
    //
    // Higher strength = slightly faster movement.
    // ----------------------------------------------------------

    final double animationSpeed =
        0.65 +
            (normalizedStrength * 0.55);

    // ----------------------------------------------------------
    // PAINTS
    // ----------------------------------------------------------

    final Paint glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter =
          const MaskFilter.blur(
        BlurStyle.normal,
        3,
      );

    final Paint barPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    // ----------------------------------------------------------
    // DRAW WAVEFORM BARS
    // ----------------------------------------------------------

    for (int i = 0; i < barCount; i++) {
      // --------------------------------------------------------
      // Position of each bar.
      // Progress shifts the waveform continuously.
      // --------------------------------------------------------

      final double normalizedIndex =
          i / barCount;

      final double animatedPhase =
          (normalizedIndex * math.pi * 4) -
              (progress *
                  math.pi *
                  2 *
                  animationSpeed);

      // --------------------------------------------------------
      // Multiple sine waves create a more natural waveform.
      // --------------------------------------------------------

      final double waveOne =
          math.sin(animatedPhase);

      final double waveTwo =
          math.sin(
                animatedPhase * 0.55 +
                    1.2,
              ) *
              0.35;

      final double combinedWave =
          ((waveOne + waveTwo) + 1) / 2;

      // --------------------------------------------------------
      // Convert wave value into bar height.
      // --------------------------------------------------------

      final double barHeight =
          minBarHeight +
              (combinedWave *
                  (maxBarHeight -
                      minBarHeight));

      final double x =
          (i * spacing) +
              ((spacing -
                      barWidth) /
                  2);

      final double top =
          centerY -
              (barHeight / 2);

      final double bottom =
          centerY +
              (barHeight / 2);

      // --------------------------------------------------------
      // Rounded bar shape.
      // --------------------------------------------------------

      final RRect barRect =
          RRect.fromLTRBR(
        x,
        top,
        x + barWidth,
        bottom,
        Radius.circular(
          barWidth / 2,
        ),
      );

      // --------------------------------------------------------
      // Glow
      // --------------------------------------------------------

      canvas.drawRRect(
        barRect,
        glowPaint,
      );

      // --------------------------------------------------------
      // Main bar
      // --------------------------------------------------------

      canvas.drawRRect(
        barRect,
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant LivePerformanceWavePainter
        oldDelegate,
  ) {
    return oldDelegate.progress !=
            progress ||
        oldDelegate.strength !=
            strength;
  }
}