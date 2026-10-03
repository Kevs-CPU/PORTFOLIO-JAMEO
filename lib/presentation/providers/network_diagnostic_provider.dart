import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/network_diagnostic_result.dart';
import '../../domain/entities/network_diagnostic_update.dart';
import '../../domain/entities/network_status.dart';
import '../../domain/usecases/run_network_diagnostic.dart';

class NetworkDiagnosticProvider extends ChangeNotifier {
  final RunNetworkDiagnostic runNetworkDiagnostic;

  NetworkDiagnosticProvider({
    required this.runNetworkDiagnostic,
  });

  StreamSubscription<NetworkDiagnosticUpdate>?
      _diagnosticSubscription;

  NetworkDiagnosticResult? _result;

  bool _isRunning = false;
  bool _isMonitoring = false;
  bool _isRestoring = false;
  bool _isOffline = false;

  String? _errorMessage;

  String _currentStage = 'Ready';

  double _progress = 0.0;

  double? _currentValue;
  double? _secondaryValue;

  double? _idlePingMs;
  double? _downloadMbps;
  double? _downloadPingMs;
  double? _uploadMbps;
  double? _uploadPingMs;
  double? _packetLossPercent;

  NetworkHealth? _health;

  NetworkDiagnosticUpdate? _latestUpdate;

  // ============================================================
  // ACTIVITY 3
  // LIVE PERFORMANCE STRENGTH
  //
  // 0.0 = very weak
  // 0.5 = average
  // 1.0 = very strong
  //
  // This value is recalculated from the latest actual
  // network measurements received from the DataSource.
  // ============================================================

  double _livePerformanceStrength = 0.5;

  // ============================================================
  // SHARED PREFERENCES KEYS
  // ============================================================

  static const String _diagnosticCompletedKey =
      'network_diagnostic_completed';

  static const String _idlePingKey =
      'network_idle_ping';

  static const String _downloadMbpsKey =
      'network_download_mbps';

  static const String _downloadPingKey =
      'network_download_ping';

  static const String _uploadMbpsKey =
      'network_upload_mbps';

  static const String _uploadPingKey =
      'network_upload_ping';

  static const String _packetLossKey =
      'network_packet_loss';

  static const String _healthKey =
      'network_health';

  // ============================================================
  // GETTERS
  // ============================================================

  NetworkDiagnosticResult? get result => _result;

  bool get isRunning => _isRunning;

  bool get isMonitoring => _isMonitoring;

  bool get isRestoring => _isRestoring;

  bool get isOffline => _isOffline;

  bool get isCompleted => _result != null;

  String? get errorMessage => _errorMessage;

  String get currentStage => _currentStage;

  double get progress => _progress;

  double? get currentValue => _currentValue;

  double? get secondaryValue => _secondaryValue;

  double? get idlePingMs => _idlePingMs;

  double? get downloadMbps => _downloadMbps;

  double? get downloadPingMs => _downloadPingMs;

  double? get uploadMbps => _uploadMbps;

  double? get uploadPingMs => _uploadPingMs;

  double? get packetLossPercent => _packetLossPercent;

  NetworkHealth? get health => _health;

  NetworkDiagnosticUpdate? get latestUpdate =>
      _latestUpdate;

  // ============================================================
  // LIVE PERFORMANCE STRENGTH GETTER
  // ============================================================

  double get livePerformanceStrength {
    return _livePerformanceStrength
        .clamp(0.0, 1.0)
        .toDouble();
  }

  // ============================================================
  // INITIALIZE / RESTORE SAVED DIAGNOSTIC
  //
  // Saved Result
  //      ↓
  // Restore values
  //      ↓
  // 100%
  //      ↓
  // Subscribe to live updates
  //      ↓
  // Start Live Monitoring
  // ============================================================

  Future<void> initialize() async {
    if (_isRestoring) {
      return;
    }

    if (_result != null) {
      return;
    }

    _isRestoring = true;

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final bool completed =
          preferences.getBool(
                _diagnosticCompletedKey,
              ) ??
              false;

      if (!completed) {
        return;
      }

      final double? idlePing =
          preferences.getDouble(
        _idlePingKey,
      );

      final double? downloadMbps =
          preferences.getDouble(
        _downloadMbpsKey,
      );

      final double? downloadPing =
          preferences.getDouble(
        _downloadPingKey,
      );

      final double? uploadMbps =
          preferences.getDouble(
        _uploadMbpsKey,
      );

      final double? uploadPing =
          preferences.getDouble(
        _uploadPingKey,
      );

      final double? packetLoss =
          preferences.getDouble(
        _packetLossKey,
      );

      final String? healthName =
          preferences.getString(
        _healthKey,
      );

      // ----------------------------------------------------------
      // Validate saved diagnostic.
      // ----------------------------------------------------------

      if (idlePing == null ||
          downloadMbps == null ||
          downloadPing == null ||
          uploadMbps == null ||
          uploadPing == null ||
          packetLoss == null ||
          healthName == null) {
        await _clearSavedDiagnostic();
        return;
      }

      final NetworkHealth? savedHealth =
          _healthFromString(healthName);

      if (savedHealth == null) {
        await _clearSavedDiagnostic();
        return;
      }

      // ----------------------------------------------------------
      // Restore saved values.
      // ----------------------------------------------------------

      _idlePingMs = idlePing;

      _downloadMbps = downloadMbps;

      _downloadPingMs = downloadPing;

      _uploadMbps = uploadMbps;

      _uploadPingMs = uploadPing;

      _packetLossPercent = packetLoss;

      _health = savedHealth;

      // ----------------------------------------------------------
      // Restore live-performance strength.
      // ----------------------------------------------------------

      _livePerformanceStrength =
          _calculatePerformanceStrength(
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
        pingMs: idlePing,
        packetLossPercent: packetLoss,
      );

      // ----------------------------------------------------------
      // Restore diagnostic result.
      // ----------------------------------------------------------

      _result = NetworkDiagnosticResult(
        idlePingMs: idlePing,
        downloadMbps: downloadMbps,
        downloadPingMs: downloadPing,
        uploadMbps: uploadMbps,
        uploadPingMs: uploadPing,
        packetLossPercent: packetLoss,
        health: savedHealth,
      );

      _currentStage =
          'Diagnostic Complete';

      _progress = 1.0;

      _errorMessage = null;

      // ----------------------------------------------------------
      // Subscribe BEFORE starting live monitoring.
      // ----------------------------------------------------------

      await _diagnosticSubscription?.cancel();

      _diagnosticSubscription =
          runNetworkDiagnostic
              .watchUpdates()
              .listen(
        _handleDiagnosticUpdate,
        onError: (Object error) {
          _errorMessage = error.toString();

          notifyListeners();
        },
      );

      notifyListeners();

      // ----------------------------------------------------------
      // Automatically restart live monitoring.
      // ----------------------------------------------------------

      await _startMonitoringInternally();
    } catch (error) {
      _errorMessage = error.toString();

      notifyListeners();
    } finally {
      _isRestoring = false;
    }
  }

  // ============================================================
  // RUN DIAGNOSTIC
  //
  // Idle Ping
  //      ↓
  // Download
  //      ↓
  // Download Ping
  //      ↓
  // Upload
  //      ↓
  // Upload Ping
  //      ↓
  // Packet Loss
  //      ↓
  // Diagnostic Complete
  //      ↓
  // Automatic Live Monitoring
  // ============================================================

  Future<void> runDiagnostic() async {
    if (_isRunning) {
      return;
    }

    if (_isMonitoring) {
      await _stopMonitoringInternally();
    }

    _isRunning = true;

    _errorMessage = null;

    _result = null;

    _currentStage = 'Starting';

    _progress = 0.0;

    _currentValue = null;

    _secondaryValue = null;

    _idlePingMs = null;

    _downloadMbps = null;

    _downloadPingMs = null;

    _uploadMbps = null;

    _uploadPingMs = null;

    _packetLossPercent = null;

    _health = null;

    _latestUpdate = null;

    _isOffline = false;

    _livePerformanceStrength = 0.5;

    notifyListeners();

    try {
      // ----------------------------------------------------------
      // Subscribe to diagnostic updates.
      // ----------------------------------------------------------

      await _diagnosticSubscription?.cancel();

      _diagnosticSubscription =
          runNetworkDiagnostic
              .watchUpdates()
              .listen(
        _handleDiagnosticUpdate,
        onError: (Object error) {
          _errorMessage = error.toString();

          notifyListeners();
        },
      );

      // ----------------------------------------------------------
      // Run complete diagnostic.
      // ----------------------------------------------------------

      final NetworkDiagnosticResult
          diagnosticResult =
          await runNetworkDiagnostic();

      // ----------------------------------------------------------
      // Save final diagnostic result in memory.
      // ----------------------------------------------------------

      _result = diagnosticResult;

      _idlePingMs =
          diagnosticResult.idlePingMs;

      _downloadMbps =
          diagnosticResult.downloadMbps;

      _downloadPingMs =
          diagnosticResult.downloadPingMs;

      _uploadMbps =
          diagnosticResult.uploadMbps;

      _uploadPingMs =
          diagnosticResult.uploadPingMs;

      _packetLossPercent =
          diagnosticResult.packetLossPercent;

      _health =
          diagnosticResult.health;

      // ----------------------------------------------------------
      // Calculate initial live-performance strength.
      // ----------------------------------------------------------

      _livePerformanceStrength =
          _calculatePerformanceStrength(
        downloadMbps:
            diagnosticResult.downloadMbps,
        uploadMbps:
            diagnosticResult.uploadMbps,
        pingMs:
            diagnosticResult.idlePingMs,
        packetLossPercent:
            diagnosticResult.packetLossPercent,
      );

      // ----------------------------------------------------------
      // Diagnostic is complete.
      // Progress MUST remain 100%.
      // ----------------------------------------------------------

      _currentStage =
          'Diagnostic Complete';

      _progress = 1.0;

      // ----------------------------------------------------------
      // Persist completed diagnostic.
      // ----------------------------------------------------------

      await _saveDiagnosticResult(
        diagnosticResult,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isRunning = false;

      notifyListeners();
    }

    // ----------------------------------------------------------
    // Automatically start live monitoring.
    // ----------------------------------------------------------

    if (_result != null &&
        _errorMessage == null) {
      await _startMonitoringInternally();
    }
  }

  // ============================================================
  // CALCULATE PERFORMANCE STRENGTH
  //
  // Uses actual:
  // - Download speed
  // - Upload speed
  // - Ping
  // - Packet loss
  //
  // Result:
  // 0.0 = weak
  // 1.0 = strong
  //
  // IMPORTANT:
  // This method can be called after EVERY new measurement.
  // Therefore the live indicator can change immediately.
  // ============================================================

  double _calculatePerformanceStrength({
    required double downloadMbps,
    required double uploadMbps,
    required double pingMs,
    required double packetLossPercent,
  }) {
    // ----------------------------------------------------------
    // Failed ping is represented internally by 9999.
    // Treat it as the worst possible ping.
    // ----------------------------------------------------------

    final double safePing =
        pingMs >= 9999.0
            ? 9999.0
            : pingMs;

    final double downloadScore =
        (downloadMbps / 20.0)
            .clamp(0.0, 1.0)
            .toDouble();

    final double uploadScore =
        (uploadMbps / 20.0)
            .clamp(0.0, 1.0)
            .toDouble();

    final double pingScore =
        safePing >= 9999.0
            ? 0.0
            : (1.0 -
                    ((safePing - 20.0) /
                        480.0))
                .clamp(0.0, 1.0)
                .toDouble();

    final double packetLossScore =
        (1.0 -
                (packetLossPercent /
                    20.0))
            .clamp(0.0, 1.0)
            .toDouble();

    return (
          downloadScore +
          uploadScore +
          pingScore +
          packetLossScore
        ) /
        4.0;
  }

  // ============================================================
  // CALCULATE NETWORK HEALTH
  //
  // Based on actual measured network performance.
  //
  // DEGRADED:
  // - Packet loss >= 20%
  // - Idle ping >= 500 ms
  // - Download ping >= 500 ms
  // - Upload ping >= 500 ms
  //
  // EXCELLENT:
  // - Download > 10 Mbps
  // - Upload > 10 Mbps
  //
  // FAIR:
  // - Download >= 2 Mbps
  // - Upload >= 2 Mbps
  //
  // POOR:
  // - Below the Fair threshold
  // ============================================================

  NetworkHealth _calculateNetworkHealth({
    required double idlePingMs,
    required double downloadMbps,
    required double downloadPingMs,
    required double uploadMbps,
    required double uploadPingMs,
    required double packetLossPercent,
  }) {
    if (packetLossPercent >= 20 ||
        idlePingMs >= 500 ||
        downloadPingMs >= 500 ||
        uploadPingMs >= 500) {
      return NetworkHealth.degraded;
    }

    if (downloadMbps > 10 &&
        uploadMbps > 10) {
      return NetworkHealth.excellent;
    }

    if (downloadMbps >= 2 &&
        uploadMbps >= 2) {
      return NetworkHealth.fair;
    }

    return NetworkHealth.poor;
  }

  // ============================================================
  // SAVE DIAGNOSTIC RESULT
  // ============================================================

  Future<void> _saveDiagnosticResult(
    NetworkDiagnosticResult diagnosticResult,
  ) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setBool(
      _diagnosticCompletedKey,
      true,
    );

    await preferences.setDouble(
      _idlePingKey,
      diagnosticResult.idlePingMs,
    );

    await preferences.setDouble(
      _downloadMbpsKey,
      diagnosticResult.downloadMbps,
    );

    await preferences.setDouble(
      _downloadPingKey,
      diagnosticResult.downloadPingMs,
    );

    await preferences.setDouble(
      _uploadMbpsKey,
      diagnosticResult.uploadMbps,
    );

    await preferences.setDouble(
      _uploadPingKey,
      diagnosticResult.uploadPingMs,
    );

    await preferences.setDouble(
      _packetLossKey,
      diagnosticResult.packetLossPercent,
    );

    await preferences.setString(
      _healthKey,
      diagnosticResult.health.name,
    );
  }

  // ============================================================
  // AUTOMATIC LIVE MONITORING
  //
  // No UI button.
  //
  // Starts automatically after:
  // - Diagnostic completion
  // - Restoring a previous diagnostic
  // ============================================================

  Future<void> _startMonitoringInternally() async {
    if (_result == null) {
      return;
    }

    if (_isRunning) {
      return;
    }

    if (_isMonitoring) {
      return;
    }

    try {
      _errorMessage = null;

      _isMonitoring = true;

      _currentStage =
          'Live Performance Monitoring';

      // Live monitoring is always 100%.
      _progress = 1.0;

      notifyListeners();

      await runNetworkDiagnostic
          .startLiveMonitoring();
    } catch (error) {
      _isMonitoring = false;

      _errorMessage = error.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // INTERNAL STOP
  //
  // No UI button.
  //
  // Used only when:
  // - Starting a new diagnostic
  // - Provider is disposed
  // ============================================================

  Future<void> _stopMonitoringInternally() async {
    if (!_isMonitoring) {
      return;
    }

    try {
      await runNetworkDiagnostic
          .stopLiveMonitoring();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isMonitoring = false;

      // Progress remains complete.
      _progress = 1.0;

      notifyListeners();
    }
  }

  // ============================================================
  // HANDLE DIAGNOSTIC UPDATE
  //
  // Receives:
  // - Diagnostic measurements
  // - Live measurements
  // - Live performance strength
  //
  // IMPORTANT:
  // Every new actual measurement is processed immediately.
  // The provider recalculates performance as soon as enough
  // current values are available.
  // ============================================================

  void _handleDiagnosticUpdate(
    NetworkDiagnosticUpdate update,
  ) {
    _latestUpdate = update;

    final String stage =
        update.stage.toLowerCase();

    _currentStage = update.stage;

    // ----------------------------------------------------------
    // OFFLINE STATE
    // ----------------------------------------------------------

    if (stage == 'offline') {
      _isOffline = true;
    }

    if (stage ==
        'live performance monitoring') {
      _isOffline = false;
    }

    // ----------------------------------------------------------
    // PROGRESS
    //
    // During live monitoring:
    // ALWAYS 100%.
    // ----------------------------------------------------------

    if (_isMonitoring) {
      _progress = 1.0;
    } else {
      _progress = update.progress
          .clamp(0.0, 1.0)
          .toDouble();
    }

    // ----------------------------------------------------------
    // CURRENT UI VALUES
    // ----------------------------------------------------------

    _currentValue = null;

    _secondaryValue = null;

    // ==========================================================
    // UPDATE ACTUAL MEASUREMENTS
    // ==========================================================

    if (update.idlePingMs != null) {
      _idlePingMs =
          update.idlePingMs;
    }

    if (update.downloadMbps != null) {
      _downloadMbps =
          update.downloadMbps;
    }

    if (update.downloadPingMs != null) {
      _downloadPingMs =
          update.downloadPingMs;
    }

    if (update.uploadMbps != null) {
      _uploadMbps =
          update.uploadMbps;
    }

    if (update.uploadPingMs != null) {
      _uploadPingMs =
          update.uploadPingMs;
    }

    if (update.packetLossPercent != null) {
      _packetLossPercent =
          update.packetLossPercent;
    }

    // ==========================================================
    // DETERMINE CURRENT MEASUREMENT
    //
    // Check PING stages BEFORE generic download/upload stages.
    // This prevents:
    //
    // "Download Ping"
    // from being treated as:
    // "Download"
    // ==========================================================

    if (stage.contains('idle ping')) {
      _currentValue =
          update.idlePingMs;
    } else if (stage.contains(
        'download ping')) {
      _currentValue =
          update.downloadPingMs;
    } else if (stage.contains(
        'download')) {
      _currentValue =
          update.downloadMbps;

      _secondaryValue =
          update.downloadPingMs;
    } else if (stage.contains(
        'upload ping')) {
      _currentValue =
          update.uploadPingMs;
    } else if (stage.contains(
        'upload')) {
      _currentValue =
          update.uploadMbps;

      _secondaryValue =
          update.uploadPingMs;
    } else if (stage.contains(
        'packet loss')) {
      _currentValue =
          update.packetLossPercent;
    }

    // ==========================================================
    // REALTIME PERFORMANCE UPDATE
    //
    // Instead of waiting for a complete new cycle, use the
    // latest actual measurements immediately.
    //
    // This means:
    //
    // New download value
    //       ↓
    // New strength
    //
    // New upload value
    //       ↓
    // New strength
    //
    // New ping
    //       ↓
    // New strength
    //
    // New packet loss
    //       ↓
    // New strength
    // ==========================================================

    _updateLivePerformanceImmediately();

    // ==========================================================
    // REALTIME HEALTH UPDATE
    //
    // Health is recalculated whenever the complete set of
    // measurements exists.
    // ==========================================================

    _updateLiveHealth();

    // ==========================================================
    // KEEP RESULT SYNCHRONIZED
    // ==========================================================

    _updateResultFromCurrentValues();

    // ==========================================================
    // SAVE CURRENT LIVE VALUES
    //
    // Fire-and-forget.
    // ==========================================================

    if (_isMonitoring) {
      _saveCurrentLiveValues();
    }

    // ==========================================================
    // DIAGNOSTIC COMPLETION
    // ==========================================================

    if (stage.contains(
      'diagnostic complete',
    )) {
      _progress = 1.0;
    }

    // ==========================================================
    // LIVE MONITORING
    // ==========================================================

    if (_isMonitoring) {
      _progress = 1.0;
    }

    // ==========================================================
    // IMPORTANT:
    // notifyListeners() happens for EVERY incoming update.
    //
    // Therefore the UI can visibly react to actual network
    // measurements as soon as they arrive.
    // ==========================================================

    notifyListeners();
  }

  // ============================================================
  // UPDATE LIVE PERFORMANCE IMMEDIATELY
  //
  // This is the main realtime fix.
  //
  // We do NOT wait for a complete diagnostic cycle.
  //
  // Whenever any actual measurement changes, the performance
  // strength is recalculated using the newest values available.
  // ============================================================

  void _updateLivePerformanceImmediately() {
    // ----------------------------------------------------------
    // Need at least one actual network measurement before
    // changing the default strength.
    // ----------------------------------------------------------

    final bool hasMeasurement =
        _idlePingMs != null ||
        _downloadMbps != null ||
        _uploadMbps != null ||
        _packetLossPercent != null;

    if (!hasMeasurement) {
      return;
    }

    // ----------------------------------------------------------
    // Use the newest available values.
    //
    // If a measurement has not arrived yet, use neutral values
    // rather than inventing a network result.
    //
    // Download/upload:
    // 0 Mbps means no measured throughput yet.
    //
    // Ping:
    // 9999 means failed/no response.
    //
    // Packet loss:
    // 0% is used only until a packet-loss measurement arrives.
    // ----------------------------------------------------------

    final double download =
        _downloadMbps ?? 0.0;

    final double upload =
        _uploadMbps ?? 0.0;

    final double ping =
        _idlePingMs ?? 9999.0;

    final double packetLoss =
        _packetLossPercent ?? 0.0;

    final double newStrength =
        _calculatePerformanceStrength(
      downloadMbps: download,
      uploadMbps: upload,
      pingMs: ping,
      packetLossPercent: packetLoss,
    );

    // ----------------------------------------------------------
    // Clamp the final result.
    // ----------------------------------------------------------

    _livePerformanceStrength =
        newStrength
            .clamp(0.0, 1.0)
            .toDouble();
  }

  // ============================================================
  // UPDATE LIVE HEALTH
  //
  // Health requires the complete set of actual measurements.
  // ============================================================

  void _updateLiveHealth() {
    final double? idlePing =
        _idlePingMs;

    final double? downloadMbps =
        _downloadMbps;

    final double? downloadPing =
        _downloadPingMs;

    final double? uploadMbps =
        _uploadMbps;

    final double? uploadPing =
        _uploadPingMs;

    final double? packetLoss =
        _packetLossPercent;

    // ----------------------------------------------------------
    // Do not calculate final health until all measurements
    // are available.
    // ----------------------------------------------------------

    if (idlePing == null ||
        downloadMbps == null ||
        downloadPing == null ||
        uploadMbps == null ||
        uploadPing == null ||
        packetLoss == null) {
      return;
    }

    _health =
        _calculateNetworkHealth(
      idlePingMs: idlePing,
      downloadMbps: downloadMbps,
      downloadPingMs: downloadPing,
      uploadMbps: uploadMbps,
      uploadPingMs: uploadPing,
      packetLossPercent: packetLoss,
    );
  }

  // ============================================================
  // UPDATE RESULT FROM CURRENT LIVE VALUES
  //
  // Keeps the complete result synchronized with actual
  // live measurements.
  // ============================================================

  void _updateResultFromCurrentValues() {
    final double? idlePing =
        _idlePingMs;

    final double? downloadMbps =
        _downloadMbps;

    final double? downloadPing =
        _downloadPingMs;

    final double? uploadMbps =
        _uploadMbps;

    final double? uploadPing =
        _uploadPingMs;

    final double? packetLoss =
        _packetLossPercent;

    final NetworkHealth? health =
        _health;

    // ----------------------------------------------------------
    // Do not replace the result until ALL measurements
    // are available.
    // ----------------------------------------------------------

    if (idlePing == null ||
        downloadMbps == null ||
        downloadPing == null ||
        uploadMbps == null ||
        uploadPing == null ||
        packetLoss == null ||
        health == null ||
        health == NetworkHealth.unknown) {
      return;
    }

    _result =
        NetworkDiagnosticResult(
      idlePingMs: idlePing,
      downloadMbps: downloadMbps,
      downloadPingMs: downloadPing,
      uploadMbps: uploadMbps,
      uploadPingMs: uploadPing,
      packetLossPercent: packetLoss,
      health: health,
    );
  }

  // ============================================================
  // SAVE CURRENT LIVE VALUES
  //
  // Fire-and-forget persistence.
  //
  // UI does not wait for SharedPreferences.
  // ============================================================

  void _saveCurrentLiveValues() {
    final double? idlePing =
        _idlePingMs;

    final double? downloadMbps =
        _downloadMbps;

    final double? downloadPing =
        _downloadPingMs;

    final double? uploadMbps =
        _uploadMbps;

    final double? uploadPing =
        _uploadPingMs;

    final double? packetLoss =
        _packetLossPercent;

    final NetworkHealth? health =
        _health;

    // ----------------------------------------------------------
    // Do not save incomplete live measurements.
    // ----------------------------------------------------------

    if (idlePing == null ||
        downloadMbps == null ||
        downloadPing == null ||
        uploadMbps == null ||
        uploadPing == null ||
        packetLoss == null ||
        health == null ||
        health == NetworkHealth.unknown) {
      return;
    }

    unawaited(
      _persistCurrentValues(
        idlePing: idlePing,
        downloadMbps: downloadMbps,
        downloadPing: downloadPing,
        uploadMbps: uploadMbps,
        uploadPing: uploadPing,
        packetLoss: packetLoss,
        health: health,
      ),
    );
  }

  // ============================================================
  // PERSIST LIVE VALUES
  // ============================================================

  Future<void> _persistCurrentValues({
    required double idlePing,
    required double downloadMbps,
    required double downloadPing,
    required double uploadMbps,
    required double uploadPing,
    required double packetLoss,
    required NetworkHealth health,
  }) async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      await preferences.setBool(
        _diagnosticCompletedKey,
        true,
      );

      await preferences.setDouble(
        _idlePingKey,
        idlePing,
      );

      await preferences.setDouble(
        _downloadMbpsKey,
        downloadMbps,
      );

      await preferences.setDouble(
        _downloadPingKey,
        downloadPing,
      );

      await preferences.setDouble(
        _uploadMbpsKey,
        uploadMbps,
      );

      await preferences.setDouble(
        _uploadPingKey,
        uploadPing,
      );

      await preferences.setDouble(
        _packetLossKey,
        packetLoss,
      );

      await preferences.setString(
        _healthKey,
        health.name,
      );
    } catch (_) {
      // Persistence failure must not stop live monitoring.
    }
  }

  // ============================================================
  // CONVERT SAVED HEALTH STRING
  // ============================================================

  NetworkHealth? _healthFromString(
    String value,
  ) {
    for (final NetworkHealth health
        in NetworkHealth.values) {
      if (health.name == value) {
        return health;
      }
    }

    return null;
  }

  // ============================================================
  // CLEAR SAVED DIAGNOSTIC
  // ============================================================

  Future<void> _clearSavedDiagnostic() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(
      _diagnosticCompletedKey,
    );

    await preferences.remove(
      _idlePingKey,
    );

    await preferences.remove(
      _downloadMbpsKey,
    );

    await preferences.remove(
      _downloadPingKey,
    );

    await preferences.remove(
      _uploadMbpsKey,
    );

    await preferences.remove(
      _uploadPingKey,
    );

    await preferences.remove(
      _packetLossKey,
    );

    await preferences.remove(
      _healthKey,
    );
  }

  // ============================================================
  // CLEAR RESULT
  //
  // This does not stop active live monitoring.
  // ============================================================

  void clearResult() {
    if (_isMonitoring) {
      return;
    }

    _result = null;

    _errorMessage = null;

    _currentStage = 'Ready';

    _progress = 0.0;

    _currentValue = null;

    _secondaryValue = null;

    _idlePingMs = null;

    _downloadMbps = null;

    _downloadPingMs = null;

    _uploadMbps = null;

    _uploadPingMs = null;

    _packetLossPercent = null;

    _health = null;

    _latestUpdate = null;

    _isOffline = false;

    _livePerformanceStrength = 0.5;

    unawaited(
      _clearSavedDiagnostic(),
    );

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _diagnosticSubscription?.cancel();

    unawaited(
      runNetworkDiagnostic
          .stopLiveMonitoring(),
    );

    super.dispose();
  }
}