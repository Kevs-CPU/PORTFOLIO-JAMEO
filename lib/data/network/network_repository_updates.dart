part of 'network_repository_impl.dart';

extension NetworkRepositoryUpdates
    on NetworkRepositoryImpl {
  // ============================================================
  // ACTIVITY 3
  // Register realtime diagnostic updates.
  // ============================================================

  void _registerDiagnosticUpdates() {
    dataSource.onDiagnosticUpdate = (
      String stage,
      double? value,
      double? secondaryValue,
      double progress,
    ) async {
      final String normalizedStage =
          stage.trim().toLowerCase();

      // ========================================================
      // IDLE PING
      // ========================================================

      if (normalizedStage == 'idle ping' ||
          normalizedStage.contains('idle ping')) {
        if (value != null) {
          _idlePingMs = value;
        }
      }

      // ========================================================
      // DOWNLOAD PING
      //
      // Check before DOWNLOAD so that
      // "Download Ping" is not treated as "Download".
      // ========================================================

      else if (normalizedStage.contains('download ping')) {
        if (value != null) {
          _downloadPingMs = value;
        }

        if (value == null &&
            secondaryValue != null) {
          _downloadPingMs = secondaryValue;
        }
      }

      // ========================================================
      // DOWNLOAD
      // ========================================================

      else if (normalizedStage.contains('download')) {
        if (value != null) {
          _downloadMbps = value;
        }

        if (secondaryValue != null) {
          _downloadPingMs = secondaryValue;
        }
      }

      // ========================================================
      // UPLOAD PING
      //
      // Check before UPLOAD.
      // ========================================================

      else if (normalizedStage.contains('upload ping')) {
        if (value != null) {
          _uploadPingMs = value;
        }

        if (value == null &&
            secondaryValue != null) {
          _uploadPingMs = secondaryValue;
        }
      }

      // ========================================================
      // UPLOAD
      // ========================================================

      else if (normalizedStage.contains('upload')) {
        if (value != null) {
          _uploadMbps = value;
        }

        if (secondaryValue != null) {
          _uploadPingMs = secondaryValue;
        }
      }

      // ========================================================
      // PACKET LOSS
      // ========================================================

      else if (normalizedStage.contains('packet loss')) {
        if (value != null) {
          _packetLossPercent = value;
        }
      }

      // ========================================================
      // LIVE PERFORMANCE
      // ========================================================

      else if (normalizedStage.contains('live performance')) {
        if (value != null) {
          _livePerformanceStrength =
              value
                  .clamp(0.0, 1.0)
                  .toDouble();
        }
      }

      // ========================================================
      // ACTIVITY 3
      // Read current performance and health from DataSource.
      // ========================================================

      if (dataSource.isLiveMonitoring) {
        _livePerformanceStrength =
            dataSource
                .getLivePerformanceStrength()
                .clamp(0.0, 1.0)
                .toDouble();

        _liveNetworkHealth =
            dataSource.liveNetworkHealth;
      } else {
        _liveNetworkHealth =
            _calculateCurrentHealth();
      }

      // ========================================================
      // ACTIVITY 3
      // Force progress to 100% during live monitoring.
      // ========================================================

      final double effectiveProgress =
          dataSource.isLiveMonitoring
              ? 1.0
              : progress
                  .clamp(0.0, 1.0)
                  .toDouble();

      // ========================================================
      // Forward complete diagnostic state.
      // ========================================================

      if (!_diagnosticUpdateController.isClosed) {
        _diagnosticUpdateController.add(
          NetworkDiagnosticUpdate(
            stage: stage,
            progress: effectiveProgress,

            idlePingMs: _idlePingMs,

            downloadMbps: _downloadMbps,
            downloadPingMs: _downloadPingMs,

            uploadMbps: _uploadMbps,
            uploadPingMs: _uploadPingMs,

            packetLossPercent:
                _packetLossPercent,

            health: _liveNetworkHealth,

            livePerformanceStrength:
                _livePerformanceStrength,
          ),
        );
      }
    };
  }

  // ============================================================
  // ACTIVITY 3
  // Calculate current network health.
  // ============================================================

  NetworkHealth _calculateCurrentHealth() {
    final double? idlePing = _idlePingMs;
    final double? downloadSpeed = _downloadMbps;
    final double? downloadPing = _downloadPingMs;
    final double? uploadSpeed = _uploadMbps;
    final double? uploadPing = _uploadPingMs;
    final double? packetLoss = _packetLossPercent;

    if (idlePing == null ||
        downloadSpeed == null ||
        downloadPing == null ||
        uploadSpeed == null ||
        uploadPing == null ||
        packetLoss == null) {
      return NetworkHealth.unknown;
    }

    if (packetLoss >= 20 ||
        idlePing >= 500 ||
        downloadPing >= 500 ||
        uploadPing >= 500) {
      return NetworkHealth.degraded;
    }

    if (downloadSpeed > 10 &&
        uploadSpeed > 10) {
      return NetworkHealth.excellent;
    }

    if (downloadSpeed >= 2 &&
        uploadSpeed >= 2) {
      return NetworkHealth.fair;
    }

    return NetworkHealth.poor;
  }
}