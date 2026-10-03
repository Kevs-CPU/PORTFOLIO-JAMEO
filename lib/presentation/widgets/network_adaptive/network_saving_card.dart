import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../providers/network_diagnostic_provider.dart';
import 'network_health_helper.dart';
import 'network_saving_tachometer.dart';

class NetworkSavingCard extends StatefulWidget {
  final NetworkDiagnosticProvider provider;

  const NetworkSavingCard({
    super.key,
    required this.provider,
  });

  @override
  State<NetworkSavingCard> createState() =>
      _NetworkSavingCardState();
}

class _NetworkSavingCardState
    extends State<NetworkSavingCard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  Duration? _lastElapsed;

  double _currentStrength = 0.0;
  double _targetStrength = 0.0;

  // ----------------------------------------------------------
  // Tachometer update timing
  //
  // The actual network measurements remain unchanged.
  // The visual target is refreshed once every second.
  // ----------------------------------------------------------
  Duration? _lastTargetUpdate;

  static const Duration _targetUpdateInterval =
      Duration(seconds: 1);

  @override
  void initState() {
    super.initState();

    _currentStrength = safeStrength(
      widget.provider.livePerformanceStrength,
    );

    _targetStrength = _currentStrength;

    _ticker = createTicker(_onTick);

    if (widget.provider.isMonitoring) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !widget.provider.isMonitoring) {
      return;
    }

    // --------------------------------------------------------
    // Update the target only once every second.
    // --------------------------------------------------------
    if (_lastTargetUpdate == null ||
        elapsed - _lastTargetUpdate! >=
            _targetUpdateInterval) {
      _targetStrength = safeStrength(
        widget.provider.livePerformanceStrength,
      );

      _lastTargetUpdate = elapsed;
    }

    // --------------------------------------------------------
    // Smoothly animate the needle toward the target.
    // --------------------------------------------------------
    final double deltaSeconds;

    if (_lastElapsed == null) {
      deltaSeconds = 1.0 / 60.0;
    } else {
      deltaSeconds =
          (elapsed - _lastElapsed!).inMicroseconds /
              1000000.0;
    }

    _lastElapsed = elapsed;

    final double difference =
        _targetStrength - _currentStrength;

    if (difference.abs() < 0.0001) {
      if (_currentStrength != _targetStrength) {
        setState(() {
          _currentStrength = _targetStrength;
        });
      }

      return;
    }

    // --------------------------------------------------------
    // Smooth response of the tachometer needle.
    // --------------------------------------------------------
    const double response = 8.0;

    final double alpha =
        1.0 -
            math.exp(
              -response * deltaSeconds,
            );

    final double nextStrength =
        _currentStrength +
            (difference * alpha);

    setState(() {
      _currentStrength =
          safeStrength(nextStrength);
    });
  }

  @override
  void didUpdateWidget(
    covariant NetworkSavingCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final double newTarget = safeStrength(
      widget.provider.livePerformanceStrength,
    );

    // --------------------------------------------------------
    // Keep the target synchronized with the latest provider
    // value. The ticker controls when the visual target moves.
    // --------------------------------------------------------
    if (!widget.provider.isMonitoring) {
      _targetStrength = newTarget;

      if (_ticker.isActive) {
        _ticker.stop();
      }

      _lastElapsed = null;
      _lastTargetUpdate = null;

      return;
    }

    // --------------------------------------------------------
    // Monitoring has just started.
    // --------------------------------------------------------
    if (!oldWidget.provider.isMonitoring &&
        widget.provider.isMonitoring) {
      _currentStrength = newTarget;
      _targetStrength = newTarget;

      _lastElapsed = null;
      _lastTargetUpdate = null;

      if (!_ticker.isActive) {
        _ticker.start();
      }

      setState(() {});
      return;
    }

    // --------------------------------------------------------
    // Make sure the ticker is running while monitoring.
    // --------------------------------------------------------
    if (!_ticker.isActive) {
      _lastElapsed = null;
      _lastTargetUpdate = null;
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    final double actualStrength = safeStrength(
      widget.provider.livePerformanceStrength,
    );

    final int percentage =
        (actualStrength * 100).round();

    final Color performance =
        performanceColor(actualStrength);

    return Row(
      children: [
        // --------------------------------------------------
        // Network performance tachometer
        // --------------------------------------------------
        SizedBox(
          width: 72,
          height: 48,
          child: NetworkSavingTachometer(
            strength: _currentStrength,
            color: performance,
          ),
        ),

        const SizedBox(width: 9),

        // --------------------------------------------------
        // Network-Saving Mode content
        // --------------------------------------------------
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --------------------------------------------------
              // Network-Saving Mode header
              // --------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Network-Saving Mode',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),
                  ),

                  // --------------------------------------------------
                  // LIVE indicator
                  // --------------------------------------------------
                  if (widget.provider.isMonitoring)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            performance.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 4,
                            color: performance,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: performance,
                              fontSize: 6,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 1),

              // --------------------------------------------------
              // Network-Saving Mode status
              // --------------------------------------------------
              Text(
                'Lightweight content is active.',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),

              const SizedBox(height: 1),

              // --------------------------------------------------
              // Network performance percentage
              // --------------------------------------------------
              Row(
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: performance,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Network performance',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme
                            .onSurface
                            .withValues(
                          alpha: 0.48,
                        ),
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}