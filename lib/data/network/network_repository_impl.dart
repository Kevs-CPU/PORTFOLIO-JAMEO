import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/entities/network_diagnostic_result.dart';
import '../../domain/entities/network_diagnostic_update.dart';
import '../../domain/entities/network_status.dart';
import '../../domain/repositories/network_repository.dart';
import 'network_data_source.dart';

part 'network_repository_connectivity.dart';
part 'network_repository_updates.dart';
part 'network_repository_measurements.dart';
part 'network_repository_diagnostic.dart';
part 'network_repository_lifecycle.dart';

// ============================================================
// ACTIVITY 2 + ACTIVITY 3
// Network Repository Implementation
//
// Connects the Domain layer with the Data layer.
//
// ACTIVITY 2:
// - Network connectivity monitoring
//
// ACTIVITY 3:
// - Network diagnostic measurements
// - Realtime diagnostic updates
// - Live performance monitoring
// - Live performance strength
// - Live network health
// - Failed measurement fallback values
// ============================================================

class NetworkRepositoryImpl implements NetworkRepository {
  final NetworkDataSource dataSource;

  // ============================================================
  // ACTIVITY 3
  // Realtime diagnostic update stream.
  // ============================================================

  final StreamController<NetworkDiagnosticUpdate>
      _diagnosticUpdateController =
      StreamController<NetworkDiagnosticUpdate>.broadcast();

  // ============================================================
  // ACTIVITY 3
  // Latest diagnostic values.
  // ============================================================

  double? _idlePingMs;
  double? _downloadMbps;
  double? _downloadPingMs;
  double? _uploadMbps;
  double? _uploadPingMs;
  double? _packetLossPercent;

  // ============================================================
  // ACTIVITY 3
  // Latest live performance strength.
  // ============================================================

  double _livePerformanceStrength = 0.5;

  // ============================================================
  // ACTIVITY 3
  // Latest completed live network health.
  // ============================================================

  NetworkHealth _liveNetworkHealth =
      NetworkHealth.unknown;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  NetworkRepositoryImpl({
    required this.dataSource,
  }) {
    _registerDiagnosticUpdates();
  }

  // ============================================================
  // ACTIVITY 2 — NETWORK CONNECTIVITY
  // ============================================================

  @override
  Future<NetworkStatus> getCurrentNetwork() {
    return _getCurrentNetwork();
  }

  @override
  Stream<NetworkStatus> watchNetwork() {
    return _watchNetwork();
  }

  // ============================================================
  // ACTIVITY 3 — MEASUREMENTS
  // ============================================================

  @override
  Future<double> measureIdlePing() {
    return _measureIdlePing();
  }

  @override
  Future<double> measureDownloadSpeed() {
    return _measureDownloadSpeed();
  }

  @override
  Future<double> measureDownloadPing() {
    return _measureDownloadPing();
  }

  @override
  Future<double> measureUploadSpeed() {
    return _measureUploadSpeed();
  }

  @override
  Future<double> measureUploadPing() {
    return _measureUploadPing();
  }

  @override
  Future<double> measurePacketLoss() {
    return _measurePacketLoss();
  }

  // ============================================================
  // ACTIVITY 3 — DIAGNOSTIC
  // ============================================================

  @override
  Future<NetworkDiagnosticResult>
      runNetworkDiagnostic() {
    return _runNetworkDiagnostic();
  }

  @override
  Stream<NetworkDiagnosticUpdate>
      watchDiagnosticUpdates() {
    return _watchDiagnosticUpdates();
  }

  // ============================================================
  // ACTIVITY 3 — LIVE MONITORING
  // ============================================================

  @override
  Future<void> startLiveMonitoring() {
    return _startLiveMonitoring();
  }

  @override
  Future<void> stopLiveMonitoring() {
    return _stopLiveMonitoring();
  }

 @override
bool get isLiveMonitoring {
  return dataSource.isLiveMonitoring;
}

  double get livePerformanceStrength {
    return _livePerformanceStrength
        .clamp(0.0, 1.0)
        .toDouble();
  }

  NetworkHealth get liveNetworkHealth {
    return _liveNetworkHealth;
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  Future<void> dispose() async {
    await _stopLiveMonitoring();
    await _diagnosticUpdateController.close();
  }
}