import 'dart:async';
import '../models/device_capabilities.dart';
import '../models/peer.dart';

class TransportPayloadEvent {
  final String peerId;
  final List<int> bytes;

  TransportPayloadEvent({required this.peerId, required this.bytes});
}

class TransportConnectionEvent {
  final String peerId;
  final bool connected;

  TransportConnectionEvent({required this.peerId, required this.connected});
}

abstract class MeshTransport {
  Future<bool> initialize(String localPeerId);
  Future<bool> startDiscovery();
  Future<void> stopDiscovery();
  Future<bool> send(String peerId, List<int> payload);
  Future<bool> broadcast(List<int> payload);
  Future<DeviceCapabilities> getCapabilities();

  Stream<Peer> get onPeerDiscovered;
  Stream<TransportPayloadEvent> get onPayloadReceived;
  Stream<TransportConnectionEvent> get onConnectionChanged;

  bool get isDemoMode;
  void dispose();
}
