import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

class NearbyChatDataSource {
  final Nearby _nearby = Nearby();

  static const String serviceId = 'com.portfolio.localchat';

  static const Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  // --------------------------------------------------
  // Start Advertising
  // --------------------------------------------------

  Future<bool> startAdvertising({
    required String deviceName,
    required OnConnectionInitiated onConnectionInitiated,
    required OnConnectionResult onConnectionResult,
    required OnDisconnected onDisconnected,
  }) async {
    return _nearby.startAdvertising(
      deviceName,
      strategy,
      serviceId: serviceId,
      onConnectionInitiated: onConnectionInitiated,
      onConnectionResult: onConnectionResult,
      onDisconnected: onDisconnected,
    );
  }

  // --------------------------------------------------
  // Start Discovery
  // --------------------------------------------------

  Future<bool> startDiscovery({
    required String deviceName,
    required OnEndpointFound onEndpointFound,
    required OnEndpointLost onEndpointLost,
  }) async {
    return _nearby.startDiscovery(
      deviceName,
      strategy,
      serviceId: serviceId,
      onEndpointFound: onEndpointFound,
      onEndpointLost: onEndpointLost,
    );
  }

  // --------------------------------------------------
  // Request Connection
  // --------------------------------------------------

  Future<bool> requestConnection({
    required String deviceName,
    required String endpointId,
    required OnConnectionInitiated onConnectionInitiated,
    required OnConnectionResult onConnectionResult,
    required OnDisconnected onDisconnected,
  }) async {
    return _nearby.requestConnection(
      deviceName,
      endpointId,
      onConnectionInitiated: onConnectionInitiated,
      onConnectionResult: onConnectionResult,
      onDisconnected: onDisconnected,
    );
  }

  // --------------------------------------------------
  // Accept Connection
  // --------------------------------------------------

  Future<bool> acceptConnection({
    required String endpointId,
    required OnPayloadReceived onPayloadReceived,
  }) async {
    return _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: onPayloadReceived,
    );
  }

  // --------------------------------------------------
  // Reject Connection
  // --------------------------------------------------

  Future<void> rejectConnection({
    required String endpointId,
  }) async {
    await _nearby.rejectConnection(endpointId);
  }

  // --------------------------------------------------
  // Send Text Message
  // --------------------------------------------------

  Future<void> sendMessage({
    required String endpointId,
    required String message,
  }) async {
    final Uint8List payload = Uint8List.fromList(
      utf8.encode(message),
    );

    await _nearby.sendBytesPayload(
      endpointId,
      payload,
    );
  }

  // --------------------------------------------------
  // Decode Received Message
  // --------------------------------------------------

  String? decodeMessage(Payload payload) {
    if (payload.type != PayloadType.BYTES) {
      return null;
    }

    final bytes = payload.bytes;

    if (bytes == null) {
      return null;
    }

    return utf8.decode(bytes);
  }

  // --------------------------------------------------
  // Disconnect
  // --------------------------------------------------

  Future<void> disconnect(String endpointId) async {
    await _nearby.disconnectFromEndpoint(endpointId);
  }

  // --------------------------------------------------
  // Stop Discovery
  // --------------------------------------------------

  Future<void> stopDiscovery() async {
    await _nearby.stopDiscovery();
  }

  // --------------------------------------------------
  // Stop Advertising
  // --------------------------------------------------

  Future<void> stopAdvertising() async {
    await _nearby.stopAdvertising();
  }

  // --------------------------------------------------
  // Stop All Endpoints
  // --------------------------------------------------

  Future<void> stopAllEndpoints() async {
    await _nearby.stopAllEndpoints();
  }
}