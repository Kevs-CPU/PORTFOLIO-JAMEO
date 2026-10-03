part of 'network_data_source.dart';

extension NetworkDataSourcePerformance
    on NetworkDataSource {

  // ============================================================
  // LIVE NETWORK HEALTH
  // ============================================================

  void _updateLiveNetworkHealth() {
    if (!_isLiveMonitoring) {
      return;
    }

    final double? downloadSpeed =
        _lastDownloadSpeed;

    final double? uploadSpeed =
        _lastUploadSpeed;

    final double? idlePing =
        _lastIdlePing;

    final double? downloadPing =
        _lastDownloadPing;

    final double? uploadPing =
        _lastUploadPing;

    final double? packetLoss =
        _lastPacketLoss;

    if (downloadSpeed == null ||
        uploadSpeed == null ||
        idlePing == null ||
        downloadPing == null ||
        uploadPing == null ||
        packetLoss == null) {
      _liveNetworkHealth =
          NetworkHealth.unknown;

      return;
    }

    _liveNetworkHealth =
        _classifyNetworkHealth(
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      idlePing: idlePing,
      downloadPing: downloadPing,
      uploadPing: uploadPing,
      packetLoss: packetLoss,
    );
  }

  // ============================================================
  // PERFORMANCE STRENGTH
  // ============================================================

  void _updateLivePerformanceStrength() {
    if (!_isLiveMonitoring) {
      return;
    }

    final List<double> scores =
        <double>[];

    if (_lastDownloadSpeed != null) {
      scores.add(
        (_lastDownloadSpeed! / 20.0)
            .clamp(0.0, 1.0)
            .toDouble(),
      );
    }

    if (_lastUploadSpeed != null) {
      scores.add(
        (_lastUploadSpeed! / 20.0)
            .clamp(0.0, 1.0)
            .toDouble(),
      );
    }

    final List<double> pings =
        <double>[];

    if (_lastIdlePing != null) {
      pings.add(_lastIdlePing!);
    }

    if (_lastDownloadPing != null) {
      pings.add(_lastDownloadPing!);
    }

    if (_lastUploadPing != null) {
      pings.add(_lastUploadPing!);
    }

    if (pings.isNotEmpty) {
      final List<double> validPings =
          pings
              .where(
                (double ping) =>
                    ping < _noPingResponse,
              )
              .toList();

      if (validPings.isEmpty) {
        scores.add(0.0);
      } else {
        scores.add(
          _pingScore(
            _average(validPings),
          ),
        );
      }
    }

    if (_lastPacketLoss != null) {
      scores.add(
        (1.0 -
                (_lastPacketLoss! / 20.0))
            .clamp(0.0, 1.0)
            .toDouble(),
      );
    }

    if (scores.isEmpty) {
      return;
    }

    _livePerformanceStrength =
        _average(scores)
            .clamp(0.0, 1.0)
            .toDouble();
  }

  // ============================================================
  // PING SCORE
  // ============================================================

  double _pingScore(double pingMs) {
    if (pingMs >= _noPingResponse) {
      return 0.0;
    }

    if (pingMs <= 20.0) {
      return 1.0;
    }

    if (pingMs >= 500.0) {
      return 0.0;
    }

    return (
      1.0 -
          ((pingMs - 20.0) / 480.0)
    ).clamp(0.0, 1.0);
  }

  // ============================================================
  // NETWORK HEALTH
  // ============================================================

  NetworkHealth _classifyNetworkHealth({
    required double downloadSpeed,
    required double uploadSpeed,
    required double idlePing,
    required double downloadPing,
    required double uploadPing,
    required double packetLoss,
  }) {
    if (packetLoss >= 20.0 ||
        idlePing >= 500.0 ||
        downloadPing >= 500.0 ||
        uploadPing >= 500.0) {
      return NetworkHealth.degraded;
    }

    if (downloadSpeed > 10.0 &&
        uploadSpeed > 10.0) {
      return NetworkHealth.excellent;
    }

    if (downloadSpeed >= 2.0 &&
        uploadSpeed >= 2.0) {
      return NetworkHealth.fair;
    }

    return NetworkHealth.poor;
  }
}