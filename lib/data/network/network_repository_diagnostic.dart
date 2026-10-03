part of 'network_repository_impl.dart';

extension NetworkRepositoryDiagnostic
    on NetworkRepositoryImpl {
  Future<NetworkDiagnosticResult>
      _runNetworkDiagnostic() async {
    await _stopLiveMonitoring();

    _idlePingMs = null;
    _downloadMbps = null;
    _downloadPingMs = null;
    _uploadMbps = null;
    _uploadPingMs = null;
    _packetLossPercent = null;

    _livePerformanceStrength = 0.5;
    _liveNetworkHealth =
        NetworkHealth.unknown;

    return await dataSource.runNetworkDiagnostic();
  }

  Stream<NetworkDiagnosticUpdate>
      _watchDiagnosticUpdates() {
    return _diagnosticUpdateController.stream;
  }
}