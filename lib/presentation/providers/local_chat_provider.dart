import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import '../../data/local_chat/datasources/local_chat_permission_data_source.dart';
import '../../data/local_chat/datasources/nearby_chat_data_source.dart';

class LocalChatProvider extends ChangeNotifier {
  final NearbyChatDataSource _chatDataSource = NearbyChatDataSource();

  final LocalChatPermissionDataSource _permissionDataSource =
      LocalChatPermissionDataSource();

  bool _isDiscovering = false;
  bool _isAdvertising = false;
  bool _isConnected = false;
  bool _isStarting = false;

  String? _connectedDeviceId;
  String? _connectedDeviceName;

  String? _errorMessage;

  // --------------------------------------------------
  // Authentication / Handshake State
  // --------------------------------------------------

  String? _pendingAuthenticationEndpointId;
  String? _pendingAuthenticationDeviceName;
  String? _pendingAuthenticationToken;

  final List<String> _messages = [];
  final List<String> _nearbyDevices = [];

  final Map<String, String> _deviceIds = {};

  // --------------------------------------------------
  // Getters
  // --------------------------------------------------

  bool get isDiscovering => _isDiscovering;

  bool get isAdvertising => _isAdvertising;

  bool get isConnected => _isConnected;

  bool get isStarting => _isStarting;

  String? get connectedDeviceId => _connectedDeviceId;

  String? get connectedDeviceName => _connectedDeviceName;

  String? get errorMessage => _errorMessage;

  List<String> get messages => List.unmodifiable(_messages);

  List<String> get nearbyDevices => List.unmodifiable(_nearbyDevices);

  // --------------------------------------------------
  // Authentication Getters
  // --------------------------------------------------

  bool get hasPendingAuthentication =>
      _pendingAuthenticationEndpointId != null &&
      _pendingAuthenticationToken != null;

  String? get pendingAuthenticationEndpointId =>
      _pendingAuthenticationEndpointId;

  String? get pendingAuthenticationDeviceName =>
      _pendingAuthenticationDeviceName;

  String? get pendingAuthenticationToken =>
      _pendingAuthenticationToken;

  // --------------------------------------------------
  // Start Local Chat
  // --------------------------------------------------

  Future<void> startLocalChat() async {
    if (_isStarting) {
      return;
    }

    _isStarting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // --------------------------------------------------
      // Request Runtime Permissions
      // --------------------------------------------------

      final permissionsGranted =
          await _permissionDataSource.requestPermissions();

      if (!permissionsGranted) {
        _errorMessage =
            'Required nearby device permissions were not granted.';
        return;
      }

      const deviceName = 'Portfolio Device';

      // --------------------------------------------------
      // Clean previous Nearby session first
      // --------------------------------------------------

      await _cleanupNearbySession();

      // Give native Nearby time to finish stopping
      // the previous advertising/discovery session.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      // --------------------------------------------------
      // Start Advertising
      // --------------------------------------------------

      final advertisingStarted =
          await _chatDataSource.startAdvertising(
        deviceName: deviceName,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
      );

      _isAdvertising = advertisingStarted;

      // --------------------------------------------------
      // Start Discovery
      // --------------------------------------------------

      final discoveryStarted =
          await _chatDataSource.startDiscovery(
        deviceName: deviceName,
        onEndpointFound: _handleEndpointFound,
        onEndpointLost: _handleEndpointLost,
      );

      _isDiscovering = discoveryStarted;

      // --------------------------------------------------
      // Final State Check
      // --------------------------------------------------

      if (!_isAdvertising && !_isDiscovering) {
        _errorMessage = 'Unable to start nearby discovery.';
      }
    } catch (e) {
      final error = e.toString();

      // --------------------------------------------------
      // Handle already-active native sessions gracefully.
      // --------------------------------------------------

      if (error.contains('STATUS_ALREADY_ADVERTISING')) {
        _isAdvertising = true;
        _errorMessage = null;
      } else if (error.contains('STATUS_ALREADY_DISCOVERING')) {
        _isDiscovering = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'Unable to start local chat: $e';
      }
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // Clean Nearby Native Session
  // --------------------------------------------------

  Future<void> _cleanupNearbySession() async {
    try {
      await _chatDataSource.stopAllEndpoints();
    } catch (_) {}

    try {
      await _chatDataSource.stopDiscovery();
    } catch (_) {}

    try {
      await _chatDataSource.stopAdvertising();
    } catch (_) {}

    _isDiscovering = false;
    _isAdvertising = false;
    _isConnected = false;

    _connectedDeviceId = null;
    _connectedDeviceName = null;

    // --------------------------------------------------
    // Clear pending authentication
    // --------------------------------------------------

    _clearPendingAuthentication();

    _nearbyDevices.clear();
    _deviceIds.clear();
  }

  // --------------------------------------------------
  // Endpoint Found
  // --------------------------------------------------

  void _handleEndpointFound(
    String endpointId,
    String endpointName,
    String serviceId,
  ) async {
    if (!_nearbyDevices.contains(endpointName)) {
      _nearbyDevices.add(endpointName);
      _deviceIds[endpointName] = endpointId;

      notifyListeners();
    }

    // --------------------------------------------------
    // Do not request another connection when:
    // - already connected
    // - another authentication is pending
    // --------------------------------------------------

    if (_isConnected || hasPendingAuthentication) {
      return;
    }

    try {
      await _chatDataSource.requestConnection(
        deviceName: 'Portfolio Device',
        endpointId: endpointId,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
      );
    } catch (e) {
      _errorMessage = 'Connection request failed: $e';
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // Endpoint Lost
  // --------------------------------------------------

  void _handleEndpointLost(String? endpointId) {
    if (endpointId == null) {
      return;
    }

    String? deviceName;

    for (final entry in _deviceIds.entries) {
      if (entry.value == endpointId) {
        deviceName = entry.key;
        break;
      }
    }

    if (deviceName != null) {
      _deviceIds.remove(deviceName);
      _nearbyDevices.remove(deviceName);

      // If the pending device disappeared,
      // cancel its pending authentication.
      if (_pendingAuthenticationEndpointId == endpointId) {
        _clearPendingAuthentication();
      }

      notifyListeners();
    }
  }

  // --------------------------------------------------
  // Connection Initiated
  // --------------------------------------------------

  void _handleConnectionInitiated(
    String endpointId,
    ConnectionInfo connectionInfo,
  ) {
    try {
      // --------------------------------------------------
      // Read authentication token supplied by Nearby.
      // nearby_connections 4.3.0 exposes this as:
      // ConnectionInfo.authenticationToken
      // --------------------------------------------------

      final authenticationToken =
          connectionInfo.authenticationToken.trim();

      final endpointName =
          connectionInfo.endpointName.trim();

      // --------------------------------------------------
      // Basic validation.
      // Never accept a connection without a token.
      // --------------------------------------------------

      if (authenticationToken.isEmpty) {
        _errorMessage =
            'Connection rejected because authentication failed.';

        _rejectConnectionSilently(endpointId);

        notifyListeners();
        return;
      }

      // --------------------------------------------------
      // Save pending authentication state.
      //
      // IMPORTANT:
      // We DO NOT call acceptConnection() yet.
      //
      // The UI must show this token and ask the user
      // to confirm that it matches the other device.
      // --------------------------------------------------

      _pendingAuthenticationEndpointId = endpointId;

      _pendingAuthenticationDeviceName =
          endpointName.isEmpty
              ? 'Nearby Device'
              : endpointName;

      _pendingAuthenticationToken = authenticationToken;

      _errorMessage =
          'Verify the authentication code before connecting.';

      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Unable to initialize secure handshake: $e';

      notifyListeners();
    }
  }

  // --------------------------------------------------
  // Confirm Authentication
  // --------------------------------------------------

  Future<void> confirmAuthentication({
    required bool accepted,
  }) async {
    final endpointId = _pendingAuthenticationEndpointId;

    if (endpointId == null) {
      _errorMessage = 'No pending connection verification.';
      notifyListeners();
      return;
    }

    try {
      if (!accepted) {
        await _chatDataSource.rejectConnection(
          endpointId: endpointId,
        );

        _errorMessage = 'Connection verification was rejected.';
        _clearPendingAuthentication();

        notifyListeners();
        return;
      }

      // --------------------------------------------------
      // User confirmed that the authentication code matches.
      // Only NOW do we accept the Nearby connection.
      // --------------------------------------------------

      await _chatDataSource.acceptConnection(
        endpointId: endpointId,
        onPayloadReceived: _handlePayload,
      );

      _errorMessage = null;

      _clearPendingAuthentication();

      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Unable to complete secure connection: $e';

      _clearPendingAuthentication();

      notifyListeners();
    }
  }

  // --------------------------------------------------
  // Clear Pending Authentication
  // --------------------------------------------------

  void _clearPendingAuthentication() {
    _pendingAuthenticationEndpointId = null;
    _pendingAuthenticationDeviceName = null;
    _pendingAuthenticationToken = null;
  }

  // --------------------------------------------------
  // Reject Connection Safely
  // --------------------------------------------------

  Future<void> _rejectConnectionSilently(
    String endpointId,
  ) async {
    try {
      await _chatDataSource.rejectConnection(
        endpointId: endpointId,
      );
    } catch (_) {}
  }

  // --------------------------------------------------
  // Connection Result
  // --------------------------------------------------

  void _handleConnectionResult(
    String endpointId,
    Status status,
  ) {
    if (status == Status.CONNECTED) {
      _isConnected = true;
      _connectedDeviceId = endpointId;

      for (final entry in _deviceIds.entries) {
        if (entry.value == endpointId) {
          _connectedDeviceName = entry.key;
          break;
        }
      }

      _errorMessage = null;
      _clearPendingAuthentication();
    } else {
      _isConnected = false;

      if (_connectedDeviceId == endpointId) {
        _connectedDeviceId = null;
        _connectedDeviceName = null;
      }

      if (_pendingAuthenticationEndpointId == endpointId) {
        _clearPendingAuthentication();
      }

      if (status == Status.REJECTED) {
        _errorMessage = 'Connection was rejected.';
      } else if (status == Status.ERROR) {
        _errorMessage = 'Connection error occurred.';
      }
    }

    notifyListeners();
  }

  // --------------------------------------------------
  // Incoming Payload
  // --------------------------------------------------

  void _handlePayload(
    String endpointId,
    Payload payload,
  ) {
    final message = _chatDataSource.decodeMessage(payload);

    if (message == null || message.trim().isEmpty) {
      return;
    }

    _messages.add(message);

    notifyListeners();
  }

  // --------------------------------------------------
  // Send Message
  // --------------------------------------------------

  Future<void> sendMessage(String message) async {
    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      return;
    }

    if (!_isConnected || _connectedDeviceId == null) {
      _errorMessage = 'No nearby device is connected.';
      notifyListeners();
      return;
    }

    try {
      await _chatDataSource.sendMessage(
        endpointId: _connectedDeviceId!,
        message: trimmedMessage,
      );

      // Add our own message to the local chat.
      _messages.add(trimmedMessage);

      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';

      notifyListeners();
    }
  }

  // --------------------------------------------------
  // Disconnected
  // --------------------------------------------------

  void _handleDisconnected(String endpointId) {
    if (_connectedDeviceId == endpointId) {
      _isConnected = false;

      _connectedDeviceId = null;
      _connectedDeviceName = null;
    }

    if (_pendingAuthenticationEndpointId == endpointId) {
      _clearPendingAuthentication();
    }

    notifyListeners();
  }

  // --------------------------------------------------
  // Stop Local Chat
  // --------------------------------------------------

  Future<void> stopLocalChat() async {
    await _cleanupNearbySession();

    notifyListeners();
  }

  // --------------------------------------------------
  // Clear Devices
  // --------------------------------------------------

  void clearDevices() {
    _nearbyDevices.clear();
    _deviceIds.clear();

    notifyListeners();
  }

  // --------------------------------------------------
  // Clear Messages
  // --------------------------------------------------

  void clearMessages() {
    _messages.clear();

    notifyListeners();
  }

  // --------------------------------------------------
  // Clear Error
  // --------------------------------------------------

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // --------------------------------------------------
  // Reset
  // --------------------------------------------------

  Future<void> reset() async {
    await _cleanupNearbySession();

    _messages.clear();
    _nearbyDevices.clear();
    _deviceIds.clear();

    _errorMessage = null;

    notifyListeners();
  }

  // --------------------------------------------------
  // Dispose
  // --------------------------------------------------

  @override
  void dispose() {
    unawaited(_chatDataSource.stopAllEndpoints());
    unawaited(_chatDataSource.stopDiscovery());
    unawaited(_chatDataSource.stopAdvertising());

    super.dispose();
  }
}