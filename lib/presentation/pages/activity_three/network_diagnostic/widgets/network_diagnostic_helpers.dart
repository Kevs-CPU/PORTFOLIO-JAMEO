import '../../../../providers/network_diagnostic_provider.dart';

// ============================================================
// ACTIVITY 3
// Network Diagnostic Helpers
//
// Provides reusable text formatting and diagnostic-stage
// helpers for the Activity 3 UI.
// ============================================================

class NetworkDiagnosticHelpers {
  const NetworkDiagnosticHelpers._();

  // ============================================================
  // ACTIVITY 3
  // Diagnostic status description.
  // ============================================================

  static String statusDescription(
    NetworkDiagnosticProvider provider,
  ) {
    final String stage =
        provider.currentStage.toLowerCase();

    if (stage.contains('download')) {
      return 'Measuring download bandwidth and ping';
    }

    if (stage.contains('upload')) {
      return 'Measuring upload bandwidth and ping';
    }

    if (stage.contains('packet')) {
      return 'Checking packet loss';
    }

    if (stage.contains('idle')) {
      return 'Measuring baseline latency';
    }

    return 'Running network performance test';
  }

  // ============================================================
  // ACTIVITY 3
  // Get the currently active diagnostic step.
  //
  // Steps:
  // 0 = Idle Ping
  // 1 = Download
  // 2 = Upload
  // 3 = Packet Loss
  // 5 = Completed
  // ============================================================

  static int getActiveStep(
    NetworkDiagnosticProvider provider,
  ) {
    if (provider.result != null) {
      return 5;
    }

    final String stage =
        provider.currentStage.toLowerCase();

    if (stage.contains('packet') ||
        stage.contains('loss')) {
      return 3;
    }

    if (stage.contains('upload')) {
      return 2;
    }

    if (stage.contains('download')) {
      return 1;
    }

    if (stage.contains('idle') ||
        stage.contains('ping')) {
      return 0;
    }

    return 0;
  }

  // ============================================================
  // ACTIVITY 3
  // Diagnostic progress description.
  // ============================================================

  static String progressDescription(
    NetworkDiagnosticProvider provider,
  ) {
    // ----------------------------------------------------------
    // Live monitoring is already running continuously.
    // ----------------------------------------------------------

    if (provider.isMonitoring) {
      return 'Live performance monitoring • Progress complete';
    }

    // ----------------------------------------------------------
    // Diagnostic has finished.
    //
    // The actual result may contain warnings if one or more
    // measurements failed.
    // ----------------------------------------------------------

    if (provider.result != null) {
      return 'Diagnostic completed';
    }

    final String stage =
        provider.currentStage.toLowerCase();

    if (stage.contains('download')) {
      return 'Measuring download bandwidth + ping';
    }

    if (stage.contains('upload')) {
      return 'Measuring upload bandwidth + ping';
    }

    if (stage.contains('packet') ||
        stage.contains('loss')) {
      return 'Checking packet loss';
    }

    if (stage.contains('idle') ||
        stage.contains('ping')) {
      return 'Measuring baseline latency';
    }

    if (provider.isRunning) {
      return 'Running network performance test';
    }

    return 'Ready to test connection performance';
  }

  // ============================================================
  // ACTIVITY 3
  // Convert the current diagnostic stage into a short label.
  // ============================================================

  static String shortStage(
    String stage,
  ) {
    final String value =
        stage.toLowerCase();

    // ----------------------------------------------------------
    // IMPORTANT:
    // Check Download Ping before Download.
    // ----------------------------------------------------------

    if (value.contains('download ping')) {
      return 'DOWNLOAD PING';
    }

    if (value.contains('download')) {
      return 'DOWNLOAD';
    }

    // ----------------------------------------------------------
    // IMPORTANT:
    // Check Upload Ping before Upload.
    // ----------------------------------------------------------

    if (value.contains('upload ping')) {
      return 'UPLOAD PING';
    }

    if (value.contains('upload')) {
      return 'UPLOAD';
    }

    if (value.contains('packet') ||
        value.contains('loss')) {
      return 'PACKET LOSS';
    }

    if (value.contains('idle') ||
        value.contains('ping')) {
      return 'IDLE PING';
    }

    // ----------------------------------------------------------
    // Diagnostic completion states.
    // ----------------------------------------------------------

    if (value.contains('warning')) {
      return 'COMPLETED WITH WARNINGS';
    }

    if (value.contains('complete')) {
      return 'COMPLETE';
    }

    return 'TESTING';
  }

  // ============================================================
  // ACTIVITY 3
  // Format numeric diagnostic values for the UI.
  //
  // Internal failure values:
  //
  //     Ping failure = 9999.0
  //
  // The value 9999.0 is NOT displayed directly to the user.
  //
  // Instead:
  //
  //     9999.0 ms -> NO RESPONSE
  //
  // This keeps the internal diagnostic logic separate from
  // the user-facing UI.
  // ============================================================

  static String formatNumber(
    double? value,
    String unit, {
    required int decimals,
  }) {
    // ----------------------------------------------------------
    // No measurement available yet.
    // ----------------------------------------------------------

    if (value == null) {
      return '--';
    }

    // ==========================================================
    // ACTIVITY 3
    // Ping failure sentinel.
    //
    // 9999.0 is used internally by the DataSource/Repository
    // to represent a failed or unavailable ping measurement.
    //
    // Never display "9999 ms" in the UI.
    // ==========================================================

    if (unit.toLowerCase() == 'ms' &&
        value >= 9999.0) {
      return 'NO RESPONSE';
    }

    // ==========================================================
    // Normal numeric formatting.
    // ==========================================================

    final String formatted =
        value.toStringAsFixed(decimals);

    return unit.isEmpty
        ? formatted
        : '$formatted $unit';
  }

  // ============================================================
  // ACTIVITY 3
  // Format ping specifically.
  //
  // This helper can be used directly by widgets that display
  // ping values.
  // ============================================================

  static String formatPing(
    double? ping,
  ) {
    if (ping == null) {
      return '--';
    }

    if (ping >= 9999.0) {
      return 'NO RESPONSE';
    }

    return '${ping.toStringAsFixed(0)} ms';
  }

  // ============================================================
  // ACTIVITY 3
  // Check whether a ping measurement failed.
  //
  // This is useful when the UI needs to change an icon,
  // description, or status based on the ping result.
  // ============================================================

  static bool isPingFailed(
    double? ping,
  ) {
    return ping != null &&
        ping >= 9999.0;
  }

  // ============================================================
  // ACTIVITY 3
  // Format speed values.
  //
  // Failed speed measurements use 0.0 internally, but zero
  // remains a valid numeric value and is therefore displayed
  // normally.
  // ============================================================

  static String formatSpeed(
    double? speed,
  ) {
    if (speed == null) {
      return '--';
    }

    return '${speed.toStringAsFixed(2)} Mbps';
  }

  // ============================================================
  // ACTIVITY 3
  // Format packet loss.
  // ============================================================

  static String formatPacketLoss(
    double? packetLoss,
  ) {
    if (packetLoss == null) {
      return '--';
    }

    return '${packetLoss.toStringAsFixed(1)}%';
  }
}