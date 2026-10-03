part of 'network_data_source.dart';

extension NetworkDataSourceHelpers
    on NetworkDataSource {
  // ============================================================
  // SEND UPDATE
  // ============================================================

  Future<void> _sendDiagnosticUpdate({
    required String stage,
    double? value,
    double? secondaryValue,
    required double progress,
  }) async {
    final callback = onDiagnosticUpdate;

    if (callback == null) {
      return;
    }

    final double effectiveProgress =
        _isLiveMonitoring
            ? 1.0
            : progress.clamp(0.0, 1.0).toDouble();

    try {
      await callback(
        stage,
        value,
        secondaryValue,
        effectiveProgress,
      );
    } catch (_) {
      // UI failure must not stop measurement.
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetDiagnosticState() {
    _lastIdlePing = null;
    _lastDownloadSpeed = null;
    _lastDownloadPing = null;
    _lastUploadSpeed = null;
    _lastUploadPing = null;
    _lastPacketLoss = null;

    _liveNetworkHealth =
        NetworkHealth.unknown;

    _livePerformanceStrength = 0.0;
  }

  // ============================================================
  // MBPS
  // ============================================================

  double _calculateMbps(
    int bytes,
    int milliseconds,
  ) {
    if (bytes <= 0 || milliseconds <= 0) {
      return 0.0;
    }

    final double seconds =
        milliseconds / 1000.0;

    return (bytes * 8) /
        seconds /
        1000000.0;
  }

  // ============================================================
  // AVERAGE
  // ============================================================

  double _average(
    List<double> values,
  ) {
    if (values.isEmpty) {
      return 0.0;
    }

    final double total =
        values.reduce(
      (double a, double b) => a + b,
    );

    return total / values.length;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stopLiveMonitoring();

    await _connectivitySubscription
        ?.cancel();

    _connectivitySubscription = null;

    _connectivityMonitorTimer?.cancel();

    _connectivityMonitorTimer = null;
  }
}