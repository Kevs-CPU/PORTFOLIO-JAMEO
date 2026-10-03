import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================
// ACTIVITY 3
// Live Performance Wave
//
// Professional bar-based network performance waveform.
//
// Bottom of every bar stays fixed.
// Only the top of each bar moves.
//
// Higher health:
// - Taller bars
// - Faster waveform
// - Stronger glow
// - Brighter appearance
// ============================================================

class LiveRainbowPerformanceWave extends StatefulWidget {
  final double strength;

  const LiveRainbowPerformanceWave({
    super.key,
    required this.strength,
  });

  @override
  State<LiveRainbowPerformanceWave> createState() =>
      _LiveRainbowPerformanceWaveState();
}

class _LiveRainbowPerformanceWaveState
    extends State<LiveRainbowPerformanceWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
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
          painter: LiveRainbowPerformanceWavePainter(
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

class LiveRainbowPerformanceWavePainter
    extends CustomPainter {
  final double progress;
  final double strength;

  const LiveRainbowPerformanceWavePainter({
    required this.progress,
    required this.strength,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    // ----------------------------------------------------------
    // NORMALIZED NETWORK HEALTH
    //
    // 0.0 = lowest
    // 1.0 = highest
    // ----------------------------------------------------------

    final double normalizedStrength =
        strength.clamp(0.0, 1.0).toDouble();

    // ----------------------------------------------------------
    // PROFESSIONAL NETWORK COLORS
    //
    // Green represents healthy network performance.
    // Cyan is used as a subtle secondary tone.
    // ----------------------------------------------------------

    final List<Color> colors = [
      const Color(0xFF45D483),
      const Color(0xFF3ED9A1),
      const Color(0xFF2EC4B6),
      const Color(0xFF45D483),
      const Color(0xFF5BE7B2),
    ];

    final List<double> stops = [
      0.0,
      0.25,
      0.50,
      0.75,
      1.0,
    ];

    // ----------------------------------------------------------
    // GRADIENT
    // ----------------------------------------------------------

    final Rect waveRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final Shader performanceShader =
        LinearGradient(
      colors: colors,
      stops: stops,
    ).createShader(waveRect);

    // ----------------------------------------------------------
    // BOTTOM ANCHOR
    //
    // The bottom never moves.
    // Only the top of each bar changes.
    // ----------------------------------------------------------

    final double bottomY =
        size.height * 0.92;

    // ----------------------------------------------------------
    // BAR HEIGHT
    //
    // Higher health = taller bars.
    // ----------------------------------------------------------

    final double minimumHeight =
        size.height * 0.08;

    final double maximumHeight =
        size.height *
            (0.25 +
                (normalizedStrength * 0.63));

    // ----------------------------------------------------------
    // WAVE SPEED
    //
    // Low health:
    //     slower movement
    //
    // High health:
    //     faster movement
    // ----------------------------------------------------------

    final double animationSpeed =
        0.35 +
            (normalizedStrength * 2.65);

    // ----------------------------------------------------------
    // GLOW
    //
    // Higher health = stronger glow.
    // ----------------------------------------------------------

    final double glowBlur =
        1.5 +
            (normalizedStrength * 6.5);

    final double glowOpacity =
        0.06 +
            (normalizedStrength * 0.28);

    // ----------------------------------------------------------
    // PAINTS
    // ----------------------------------------------------------

    final Paint glowPaint = Paint()
      ..shader = performanceShader
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        glowBlur,
      );

    final Paint barPaint = Paint()
      ..shader = performanceShader
      ..style = PaintingStyle.fill;

    // ----------------------------------------------------------
    // BRIGHT HIGHLIGHT
    //
    // Becomes stronger as network health increases.
    // ----------------------------------------------------------

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(
        alpha:
            0.02 +
                (normalizedStrength * 0.16),
      )
      ..style = PaintingStyle.fill;

    // ----------------------------------------------------------
    // DRAW WAVEFORM BARS
    // ----------------------------------------------------------

    const int barCount = 18;

    final double spacing =
        size.width / barCount;

    final double barWidth =
        spacing * 0.42;

    for (int i = 0;
        i < barCount;
        i++) {
      // --------------------------------------------------------
      // BAR POSITION
      // --------------------------------------------------------

      final double normalizedIndex =
          i / (barCount - 1);

      // --------------------------------------------------------
      // MOVING WAVE
      //
      // Health affects the speed of movement.
      // --------------------------------------------------------

      final double phase =
          (normalizedIndex *
                  math.pi *
                  2.4) -
              (progress *
                  math.pi *
                  2 *
                  animationSpeed);

      // --------------------------------------------------------
      // PRIMARY WAVE
      // --------------------------------------------------------

      final double primaryWave =
          math.sin(phase);

      // --------------------------------------------------------
      // SECONDARY WAVE
      //
      // Adds natural variation between bars.
      // --------------------------------------------------------

      final double secondaryWave =
          math.sin(
                phase * 0.55 +
                    1.2,
              ) *
              0.25;

      // --------------------------------------------------------
      // COMBINE WAVES
      // --------------------------------------------------------

      final double combinedWave =
          ((primaryWave +
                      secondaryWave) +
                  1.0) /
              2.0;

      final double normalizedWave =
          combinedWave.clamp(
        0.0,
        1.0,
      );

      // --------------------------------------------------------
      // BAR HEIGHT
      // --------------------------------------------------------

      final double barHeight =
          minimumHeight +
              (normalizedWave *
                  (maximumHeight -
                      minimumHeight));

      // --------------------------------------------------------
      // X POSITION
      // --------------------------------------------------------

      final double x =
          (i * spacing) +
              ((spacing -
                      barWidth) /
                  2);

      // --------------------------------------------------------
      // TOP POSITION
      //
      // ONLY THE TOP MOVES.
      // --------------------------------------------------------

      final double topY =
          bottomY -
              barHeight;

      // --------------------------------------------------------
      // ROUNDED BAR
      //
      // Bottom remains fixed.
      // Top follows the waveform.
      // --------------------------------------------------------

      final RRect barRect =
          RRect.fromLTRBAndCorners(
        x,
        topY,
        x + barWidth,
        bottomY,
        topLeft: Radius.circular(
          barWidth / 2,
        ),
        topRight: Radius.circular(
          barWidth / 2,
        ),
      );

      // --------------------------------------------------------
      // GLOW
      // --------------------------------------------------------

      if (glowOpacity > 0.08) {
        canvas.drawRRect(
          barRect,
          glowPaint,
        );
      }

      // --------------------------------------------------------
      // MAIN PERFORMANCE BAR
      // --------------------------------------------------------

      canvas.drawRRect(
        barRect,
        barPaint,
      );

      // --------------------------------------------------------
      // BRIGHT HIGHLIGHT
      //
      // Higher health produces a more visible highlight.
      // --------------------------------------------------------

      if (normalizedStrength > 0.35) {
        canvas.drawRRect(
          barRect,
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant
        LiveRainbowPerformanceWavePainter
            oldDelegate,
  ) {
    return oldDelegate.progress !=
            progress ||
        oldDelegate.strength !=
            strength;
  }
}