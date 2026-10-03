import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalChatPermissionDataSource {
  Future<bool> requestPermissions() async {
    final permissions = <Permission>[
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    final results = await permissions.request();

    for (final entry in results.entries) {
      debugPrint(
        '[LocalChat Permission] ${entry.key}: ${entry.value}',
      );
    }

    final allGranted = results.values.every(
      (status) => status.isGranted,
    );

    debugPrint(
      '[LocalChat Permission] All granted: $allGranted',
    );

    return allGranted;
  }

  Future<bool> arePermissionsGranted() async {
    final permissions = <Permission>[
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    final statuses = <PermissionStatus>[];

    for (final permission in permissions) {
      final status = await permission.status;

      debugPrint(
        '[LocalChat Permission Check] $permission: $status',
      );

      statuses.add(status);
    }

    return statuses.every(
      (status) => status.isGranted,
    );
  }

  Future<bool> openSettings() async {
    return openAppSettings();
  }
}