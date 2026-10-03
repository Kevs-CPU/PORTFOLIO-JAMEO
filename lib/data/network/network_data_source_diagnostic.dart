part of 'network_data_source.dart';

extension NetworkDataSourceDiagnostic
    on NetworkDataSource {
  // ============================================================
  // ACTIVITY 3
  // COMPLETE NETWORK DIAGNOSTIC
  // ============================================================

  Future<NetworkDiagnosticResult> runNetworkDiagnostic() async {
    _resetDiagnosticState();

    final double? idlePing =
        await _runDiagnosticStepSafely(
      action: measureIdlePing,
      stage: 'Idle Ping',
      progress: 0.10,
    );

    final double? downloadSpeed =
        await _runDiagnosticStepSafely(
      action: measureDownloadSpeed,
      stage: 'Download',
      progress: 0.40,
    );

    final double? downloadPing =
        await _runDiagnosticStepSafely(
      action: measureDownloadPing,
      stage: 'Download Ping',
      progress: 0.50,
    );

    final double? uploadSpeed =
        await _runDiagnosticStepSafely(
      action: measureUploadSpeed,
      stage: 'Upload',
      progress: 0.65,
    );

    final double? uploadPing =
        await _runDiagnosticStepSafely(
      action: measureUploadPing,
      stage: 'Upload Ping',
      progress: 0.75,
    );

    final double? packetLoss =
        await _runDiagnosticStepSafely(
      action: measurePacketLoss,
      stage: 'Packet Loss',
      progress: 1.0,
    );

    final double finalIdlePing =
        idlePing ?? _noPingResponse;

    final double finalDownloadSpeed =
        downloadSpeed ?? _noThroughput;

    final double finalDownloadPing =
        downloadPing ?? _noPingResponse;

    final double finalUploadSpeed =
        uploadSpeed ?? _noThroughput;

    final double finalUploadPing =
        uploadPing ?? _noPingResponse;

    final double finalPacketLoss =
        packetLoss ?? _completePacketLoss;

    final NetworkHealth health =
        _classifyNetworkHealth(
      downloadSpeed: finalDownloadSpeed,
      uploadSpeed: finalUploadSpeed,
      idlePing: finalIdlePing,
      downloadPing: finalDownloadPing,
      uploadPing: finalUploadPing,
      packetLoss: finalPacketLoss,
    );

    // ============================================================
    // ALL STEPS ATTEMPTED
    // ============================================================

    await _sendDiagnosticUpdate(
      stage: 'Diagnostic Complete',
      value: null,
      secondaryValue: null,
      progress: 1.0,
    );

    return NetworkDiagnosticResult(
      idlePingMs: finalIdlePing,
      downloadMbps: finalDownloadSpeed,
      downloadPingMs: finalDownloadPing,
      uploadMbps: finalUploadSpeed,
      uploadPingMs: finalUploadPing,
      packetLossPercent: finalPacketLoss,
      health: health,
    );
  }

  // ============================================================
  // SAFE STEP
  // ============================================================

  Future<double?> _runDiagnosticStepSafely({
    required Future<double?> Function() action,
    required String stage,
    required double progress,
  }) async {
    try {
      return await action().timeout(
        const Duration(seconds: 20),
      );
    } on TimeoutException {
      await _sendDiagnosticUpdate(
        stage: stage,
        value: null,
        secondaryValue: null,
        progress: progress,
      );

      return null;
    } catch (_) {
      await _sendDiagnosticUpdate(
        stage: stage,
        value: null,
        secondaryValue: null,
        progress: progress,
      );

      return null;
    }
  }
}