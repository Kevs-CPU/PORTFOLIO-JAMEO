part of 'network_data_source.dart';

extension NetworkDataSourceLiveMonitor
    on NetworkDataSource {

  // ============================================================
  // START LIVE MONITORING
  // ============================================================

  Future<void> startLiveMonitoring() async {
    if (_isLiveMonitoring) {
      return;
    }

    _isLiveMonitoring = true;

    _startConnectivityMonitor();

    final bool networkAvailable =
        await _isNetworkAvailable();

    if (!_isLiveMonitoring) {
      return;
    }

    if (!networkAvailable) {
      _isCurrentlyOffline = true;

      await _sendDiagnosticUpdate(
        stage: 'Offline',
        value: null,
        secondaryValue: null,
        progress: 1.0,
      );
    } else {
      _isCurrentlyOffline = false;

      await _sendDiagnosticUpdate(
        stage:
            'Live Performance Monitoring',
        value: _livePerformanceStrength,
        secondaryValue: null,
        progress: 1.0,
      );
    }

    _liveMonitoringTask =
        _runLiveMonitoringLoop();
  }

  // ============================================================
  // CONNECTIVITY MONITOR
  // ============================================================

  void _startConnectivityMonitor() {
    _connectivityMonitorTimer?.cancel();

    _connectivityMonitorTimer =
        Timer.periodic(
      const Duration(seconds: 1),
      (_) async {
        if (!_isLiveMonitoring) {
          return;
        }

        if (_connectivityCheckInProgress) {
          return;
        }

        _connectivityCheckInProgress = true;

        try {
          final bool available =
              await _isNetworkAvailable();

          if (!_isLiveMonitoring) {
            return;
          }

          if (available) {
            await _handleConnectivityOnline();
          } else {
            await _handleConnectivityOffline();
          }
        } finally {
          _connectivityCheckInProgress =
              false;
        }
      },
    );
  }

  // ============================================================
  // LIVE LOOP
  // ============================================================

  Future<void> _runLiveMonitoringLoop() async {
    while (_isLiveMonitoring) {
      try {
        final bool available =
            await _isNetworkAvailable();

        if (!_isLiveMonitoring) {
          break;
        }

        if (!available) {
          _isCurrentlyOffline = true;

          await _sendDiagnosticUpdate(
            stage: 'Offline',
            value: null,
            secondaryValue: null,
            progress: 1.0,
          );

          await Future<void>.delayed(
            const Duration(seconds: 3),
          );

          continue;
        }

        if (_isCurrentlyOffline) {
          _isCurrentlyOffline = false;

          await _sendDiagnosticUpdate(
            stage:
                'Live Performance Monitoring',
            value: _livePerformanceStrength,
            secondaryValue: null,
            progress: 1.0,
          );
        }

        await measureIdlePing();

        if (!_isLiveMonitoring ||
            _isCurrentlyOffline) {
          continue;
        }

        await measureDownloadSpeed(
          liveMeasurement: true,
        );

        if (!_isLiveMonitoring ||
            _isCurrentlyOffline) {
          continue;
        }

        await measureDownloadPing();

        if (!_isLiveMonitoring ||
            _isCurrentlyOffline) {
          continue;
        }

        await measureUploadSpeed(
          liveMeasurement: true,
        );

        if (!_isLiveMonitoring ||
            _isCurrentlyOffline) {
          continue;
        }

        await measureUploadPing();

        if (!_isLiveMonitoring ||
            _isCurrentlyOffline) {
          continue;
        }

        await measurePacketLoss();

        if (!_isLiveMonitoring ||
            _isCurrentlyOffline) {
          continue;
        }

        _updateLivePerformanceStrength();

        _updateLiveNetworkHealth();

        await _sendDiagnosticUpdate(
          stage: 'Live Performance',
          value:
              _livePerformanceStrength,
          secondaryValue: null,
          progress: 1.0,
        );
      } catch (_) {
        if (!_isLiveMonitoring) {
          break;
        }

        final bool available =
            await _isNetworkAvailable();

        if (!available) {
          _isCurrentlyOffline = true;

          await _sendDiagnosticUpdate(
            stage: 'Offline',
            value: null,
            secondaryValue: null,
            progress: 1.0,
          );
        }
      }

      if (!_isLiveMonitoring) {
        break;
      }

      await Future<void>.delayed(
        const Duration(seconds: 3),
      );
    }
  }

  // ============================================================
  // STOP LIVE MONITORING
  // ============================================================

  Future<void> stopLiveMonitoring() async {
    _isLiveMonitoring = false;

    _connectivityMonitorTimer?.cancel();
    _connectivityMonitorTimer = null;

    await _connectivitySubscription?.cancel();

    _connectivitySubscription = null;

    final Future<void>? task =
        _liveMonitoringTask;

    if (task != null) {
      try {
        await task;
      } catch (_) {
        // Ignore shutdown errors.
      }
    }

    _liveMonitoringTask = null;

    _isCurrentlyOffline = false;
  }
}