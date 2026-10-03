part of 'network_data_source.dart';

extension NetworkDataSourceConnectivity
    on NetworkDataSource {

  // ============================================================
  // CONNECTIVITY
  // ============================================================

  Future<List<ConnectivityResult>>
      getCurrentConnectivity() {
    return connectivity.checkConnectivity();
  }

  Stream<List<ConnectivityResult>>
      watchConnectivity() {
    return connectivity.onConnectivityChanged;
  }

  Future<bool> _isNetworkAvailable() async {
    try {
      final List<ConnectivityResult> results =
          await getCurrentConnectivity();

      return results.any(
        (ConnectivityResult result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn ||
            result == ConnectivityResult.other,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CONNECTIVITY LISTENER
  // ============================================================

  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();

    _connectivitySubscription =
        watchConnectivity().listen(
      (List<ConnectivityResult> results) async {
        final bool isAvailable = results.any(
          (ConnectivityResult result) =>
              result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.ethernet ||
              result == ConnectivityResult.vpn ||
              result == ConnectivityResult.other,
        );

        if (!isAvailable) {
          await _handleConnectivityOffline();
        } else {
          await _handleConnectivityOnline();
        }
      },
    );
  }

  Future<void> _handleConnectivityOffline() async {
    if (!_isLiveMonitoring) {
      return;
    }

    if (_isCurrentlyOffline) {
      return;
    }

    _isCurrentlyOffline = true;

    await _sendDiagnosticUpdate(
      stage: 'Offline',
      value: null,
      secondaryValue: null,
      progress: 1.0,
    );
  }

  Future<void> _handleConnectivityOnline() async {
    if (!_isLiveMonitoring) {
      return;
    }

    if (!_isCurrentlyOffline) {
      return;
    }

    final bool available =
        await _isNetworkAvailable();

    if (!available) {
      return;
    }

    _isCurrentlyOffline = false;

    await _sendDiagnosticUpdate(
      stage: 'Live Performance Monitoring',
      value: null,
      secondaryValue: null,
      progress: 1.0,
    );
  }
}