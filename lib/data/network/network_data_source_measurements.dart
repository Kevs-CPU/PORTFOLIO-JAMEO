part of 'network_data_source.dart';

// ============================================================
// ACTIVITY 3
// NETWORK MEASUREMENTS
// ============================================================
//
// Cloudflare Speed Test endpoints:
// - /              -> latency / connectivity
// - /__down        -> download measurement
// - /__up          -> upload measurement
//
// The same measurement logic is used for:
// - Run Diagnostic
// - Live Performance Monitoring
// ============================================================

final Uri _pingUrl = Uri.parse(
  'https://speed.cloudflare.com/',
);

Uri _downloadUrl(int bytes) {
  return Uri.parse(
    'https://speed.cloudflare.com/__down?bytes=$bytes',
  );
}

final Uri _uploadUrl = Uri.parse(
  'https://speed.cloudflare.com/__up',
);

const int _packetLossAttempts = 10;

const int _downloadBytes = 5 * 1024 * 1024;
const int _uploadBytes = 5 * 1024 * 1024;

const int _uploadChunkSize = 64 * 1024;

const Duration _requestTimeout =
    Duration(seconds: 15);

const Duration _uploadStreamTimeout =
    Duration(seconds: 20);

const int _liveDownloadBytes =
    512 * 1024;

const int _liveUploadBytes =
    512 * 1024;

const double _noPingResponse = 9999.0;
const double _noThroughput = 0.0;
const double _completePacketLoss = 100.0;

// ============================================================
// MEASUREMENTS
// ============================================================

extension NetworkDataSourceMeasurements
    on NetworkDataSource {

  // ==========================================================
  // IDLE PING
  // ==========================================================

  Future<double?> measureIdlePing() async {
    final double? ping =
        await _measureSinglePing();

    await _sendDiagnosticUpdate(
      stage: 'Idle Ping',
      value: ping,
      secondaryValue: null,
      progress: 0.10,
    );

    return ping;
  }

  // ==========================================================
  // DOWNLOAD SPEED
  // ==========================================================

  Future<double?> measureDownloadSpeed({
    bool liveMeasurement = false,
  }) async {
    final int bytes = liveMeasurement
        ? _liveDownloadBytes
        : _downloadBytes;

    final Stopwatch stopwatch =
        Stopwatch()..start();

    int receivedBytes = 0;

    final http.Client client =
        http.Client();

    try {
      final http.Request request =
          http.Request(
        'GET',
        _downloadUrl(bytes),
      );

      final http.StreamedResponse response =
          await client
              .send(request)
              .timeout(_requestTimeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Download failed: '
          '${response.statusCode}',
        );
      }

      await for (
        final List<int> chunk
            in response.stream
      ) {
        receivedBytes += chunk.length;

        if (!liveMeasurement) {
          final double progress =
              0.20 +
                  (receivedBytes / bytes)
                          .clamp(0.0, 1.0) *
                      0.20;

          await _sendDiagnosticUpdate(
            stage: 'Download',
            value: null,
            secondaryValue: null,
            progress: progress,
          );
        }
      }

      stopwatch.stop();

      if (receivedBytes <= 0) {
        await _sendDiagnosticUpdate(
          stage: 'Download',
          value: null,
          secondaryValue: null,
          progress:
              liveMeasurement ? 1.0 : 0.40,
        );

        return null;
      }

      final double mbps =
          _calculateMbps(
        receivedBytes,
        stopwatch.elapsedMilliseconds,
      );

      await _sendDiagnosticUpdate(
        stage: 'Download',
        value: mbps,
        secondaryValue: null,
        progress:
            liveMeasurement ? 1.0 : 0.40,
      );

      return mbps;
    } catch (_) {
      stopwatch.stop();

      await _sendDiagnosticUpdate(
        stage: 'Download',
        value: null,
        secondaryValue: null,
        progress:
            liveMeasurement ? 1.0 : 0.40,
      );

      return null;
    } finally {
      client.close();
    }
  }

  // ==========================================================
  // DOWNLOAD PING
  // ==========================================================

  Future<double?> measureDownloadPing() async {
    final double? ping =
        await _measureSinglePing();

    await _sendDiagnosticUpdate(
      stage: 'Download Ping',
      value: ping,
      secondaryValue: null,
      progress: 0.50,
    );

    return ping;
  }

  // ==========================================================
  // UPLOAD SPEED
  // ==========================================================

  Future<double?> measureUploadSpeed({
    bool liveMeasurement = false,
  }) async {
    final int bytes = liveMeasurement
        ? _liveUploadBytes
        : _uploadBytes;

    final Stopwatch stopwatch =
        Stopwatch()..start();

    final http.Client client =
        http.Client();

    final http.StreamedRequest request =
        http.StreamedRequest(
      'POST',
      _uploadUrl,
    );

    request.contentLength = bytes;

    try {
      final Future<http.StreamedResponse>
          responseFuture =
          client
              .send(request)
              .timeout(
                _uploadStreamTimeout,
              );

      int sentBytes = 0;

      while (sentBytes < bytes) {
        final int remaining =
            bytes - sentBytes;

        final int chunkSize =
            remaining < _uploadChunkSize
                ? remaining
                : _uploadChunkSize;

        request.sink.add(
          Uint8List(chunkSize),
        );

        sentBytes += chunkSize;

        if (!liveMeasurement) {
          final double progress =
              0.45 +
                  (sentBytes / bytes)
                          .clamp(0.0, 1.0) *
                      0.20;

          await _sendDiagnosticUpdate(
            stage: 'Upload',
            value: null,
            secondaryValue: null,
            progress: progress,
          );
        }
      }

      await request.sink.close();

      final http.StreamedResponse response =
          await responseFuture;

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Upload failed: '
          '${response.statusCode}',
        );
      }

      await response.stream
          .drain()
          .timeout(_uploadStreamTimeout);

      stopwatch.stop();

      if (sentBytes <= 0) {
        await _sendDiagnosticUpdate(
          stage: 'Upload',
          value: null,
          secondaryValue: null,
          progress:
              liveMeasurement ? 1.0 : 0.65,
        );

        return null;
      }

      final double mbps =
          _calculateMbps(
        sentBytes,
        stopwatch.elapsedMilliseconds,
      );

      await _sendDiagnosticUpdate(
        stage: 'Upload',
        value: mbps,
        secondaryValue: null,
        progress:
            liveMeasurement ? 1.0 : 0.65,
      );

      return mbps;
    } catch (_) {
      stopwatch.stop();

      try {
        await request.sink.close();
      } catch (_) {
        // Ignore cleanup errors.
      }

      await _sendDiagnosticUpdate(
        stage: 'Upload',
        value: null,
        secondaryValue: null,
        progress:
            liveMeasurement ? 1.0 : 0.65,
      );

      return null;
    } finally {
      client.close();
    }
  }

  // ==========================================================
  // UPLOAD PING
  // ==========================================================

  Future<double?> measureUploadPing() async {
    final double? ping =
        await _measureSinglePing();

    await _sendDiagnosticUpdate(
      stage: 'Upload Ping',
      value: ping,
      secondaryValue: null,
      progress: 0.75,
    );

    return ping;
  }

  // ==========================================================
  // SINGLE PING
  // ==========================================================

  Future<double?> _measureSinglePing() async {
    final http.Client client =
        http.Client();

    try {
      final Stopwatch stopwatch =
          Stopwatch()..start();

      final http.Response response =
          await client
              .get(_pingUrl)
              .timeout(_requestTimeout);

      stopwatch.stop();

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return null;
      }

      return stopwatch.elapsedMicroseconds /
          1000.0;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  // ==========================================================
  // PACKET LOSS
  // ==========================================================

  Future<double?> measurePacketLoss() async {
    int failedAttempts = 0;

    final http.Client client =
        http.Client();

    try {
      for (int i = 0;
          i < _packetLossAttempts;
          i++) {
        try {
          final http.Response response =
              await client
                  .get(_pingUrl)
                  .timeout(_requestTimeout);

          if (response.statusCode < 200 ||
              response.statusCode >= 300) {
            failedAttempts++;
          }
        } catch (_) {
          failedAttempts++;
        }

        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );
      }

      final double packetLoss =
          (failedAttempts /
                  _packetLossAttempts) *
              100.0;

      await _sendDiagnosticUpdate(
        stage: 'Packet Loss',
        value: packetLoss,
        secondaryValue: null,
        progress: 1.0,
      );

      return packetLoss;
    } catch (_) {
      await _sendDiagnosticUpdate(
        stage: 'Packet Loss',
        value: _completePacketLoss,
        secondaryValue: null,
        progress: 1.0,
      );

      return _completePacketLoss;
    } finally {
      client.close();
    }
  }
}