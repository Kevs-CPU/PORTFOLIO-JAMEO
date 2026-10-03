import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/network_diagnostic_result.dart';
import '../../domain/entities/network_status.dart';

part 'network_data_source_connectivity.dart';
part 'network_data_source_measurements.dart';
part 'network_data_source_live_monitor.dart';
part 'network_data_source_performance.dart';
part 'network_data_source_helpers.dart';
part 'network_data_source_diagnostic.dart';

class NetworkDataSource {
  final Connectivity connectivity;

  NetworkDataSource({
    required this.connectivity,
  }) {
    _startConnectivityListener();
  }

  // ============================================================
  // CALLBACK
  // ============================================================

  Future<void> Function(
    String stage,
    double? value,
    double? secondaryValue,
    double progress,
  )? onDiagnosticUpdate;

  // ============================================================
  // CONNECTIVITY STATE
  // ============================================================

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  Timer? _connectivityMonitorTimer;

  bool _connectivityCheckInProgress = false;

  bool _isCurrentlyOffline = false;

  // ============================================================
  // LIVE MONITORING STATE
  // ============================================================

  bool _isLiveMonitoring = false;

  Future<void>? _liveMonitoringTask;

  // ============================================================
  // LIVE PERFORMANCE
  // ============================================================

  double _livePerformanceStrength = 0.0;

  NetworkHealth _liveNetworkHealth =
      NetworkHealth.unknown;

  // ============================================================
  // LIVE MEASUREMENT CACHE
  // ============================================================

  double? _lastIdlePing;

  double? _lastDownloadSpeed;

  double? _lastDownloadPing;

  double? _lastUploadSpeed;

  double? _lastUploadPing;

  double? _lastPacketLoss;

  // ============================================================
  // DIAGNOSTIC PROGRESS
  // ============================================================

  double _downloadCurrentProgress = 0.20;

  double _uploadCurrentProgress = 0.45;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLiveMonitoring {
    return _isLiveMonitoring;
  }

  double get livePerformanceStrength {
    return _livePerformanceStrength
        .clamp(0.0, 1.0)
        .toDouble();
  }

  NetworkHealth get liveNetworkHealth {
    return _liveNetworkHealth;
  }

  double getLivePerformanceStrength() {
    return livePerformanceStrength;
  }
}