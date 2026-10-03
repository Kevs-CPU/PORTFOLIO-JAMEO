import 'package:flutter/material.dart';

import '../../../../providers/network_diagnostic_provider.dart';
import '../../../../widgets/network_adaptive/network_saving_card.dart';
import 'network_diagnostic_helpers.dart';

// ============================================================
// ACTIVITY 3
// Network Diagnostic Status Card
//
// IMPORTANT:
// The outer card keeps the ORIGINAL Activity 3 size:
// - Height: 72
// - Horizontal padding: 14
// - Same border radius
//
// When monitoring is active, NetworkSavingCard is displayed
// INSIDE the same fixed-size card.
// ============================================================

class NetworkDiagnosticStatusCard extends StatelessWidget {
  final NetworkDiagnosticProvider provider;

  const NetworkDiagnosticStatusCard({
    super.key,
    required this.provider,
  });

  static const Color _success = Color(0xFF45D483);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
        Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool running =
        provider.isRunning;

    final bool monitoring =
        provider.isMonitoring;

    final bool completed =
        provider.result != null;

    final bool offline =
        provider.isOffline;

    // ==========================================================
    // LIVE MONITORING
    //
    // IMPORTANT:
    // Keep EXACTLY the same card height as the original card.
    // ==========================================================

   if (monitoring && !offline) {
      return Container(
        width: double.infinity,
        height: 72,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: _success.withValues(
              alpha: 0.30,
            ),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: NetworkSavingCard(
          provider: provider,
        ),
      );
    }

    // ==========================================================
    // NORMAL STATUS CARD
    // ==========================================================

    final Color color = offline
        ? colorScheme.error
        : running
            ? colorScheme.primary
            : completed
                ? _success
                : colorScheme.onSurface.withValues(
                    alpha: 0.60,
                  );

    final String title = offline
        ? 'Offline — Monitoring Paused'
        : running
            ? 'Diagnostic Running'
            : completed
                ? 'Diagnostic Complete'
                : 'Diagnostic Ready';

    final String description = offline
        ? 'Network unavailable. Last valid measurements are retained.'
        : running
            ? NetworkDiagnosticHelpers.statusDescription(
                provider,
              )
            : completed
                ? 'Latest network test is available'
                : 'Ready to measure connection performance';

    return Container(
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: offline
              ? colorScheme.error.withValues(
                  alpha: 0.30,
                )
              : completed
                  ? _success.withValues(
                      alpha: 0.30,
                    )
                  : colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // STATUS ICON
          // ====================================================

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              offline
                  ? Icons.cloud_off_rounded
                  : running
                      ? Icons.sync_rounded
                      : completed
                          ? Icons
                              .check_circle_outline_rounded
                          : Icons
                              .network_check_rounded,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 11),

          // ====================================================
          // STATUS TEXT
          // ====================================================

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.60,
                    ),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // RUNNING STAGE
          // ====================================================

          if (running && !offline)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color: colorScheme
                    .primary
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                NetworkDiagnosticHelpers
                    .shortStage(
                  provider.currentStage,
                ),
                style: TextStyle(
                  color:
                      colorScheme.primary,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

          // ====================================================
          // COMPLETED
          // ====================================================

          if (completed)
            const Icon(
              Icons.check_circle_rounded,
              color: _success,
              size: 21,
            ),
        ],
      ),
    );
  }
}