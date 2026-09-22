import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/logging/mesh_logger.dart';
import '../models/device_capabilities.dart';
import '../models/mesh_message.dart';
import '../models/peer.dart';
import 'mesh_transport.dart';

class SimulatedNode {
  final String meshId;
  final String displayName;
  bool isOnline;
  final int hopDistance;
  final double latitude;
  final double longitude;
  final bool isRescue;
  final bool isShelter;

  SimulatedNode({
    required this.meshId,
    required this.displayName,
    this.isOnline = true,
    required this.hopDistance,
    required this.latitude,
    required this.longitude,
    this.isRescue = false,
    this.isShelter = false,
  });
}

/// Dedicated, explicitly labeled development and demonstration sandbox.
/// Demonstrates multi-hop packet routing:
/// Node A (User) -> Node B (Volunteer) -> Node C (Shelter) -> Node D (Rescue Gateway)
class DemoMeshTransport implements MeshTransport {
  final StreamController<Peer> _peerDiscoveredController = StreamController<Peer>.broadcast();
  final StreamController<TransportPayloadEvent> _payloadReceivedController = StreamController<TransportPayloadEvent>.broadcast();
  final StreamController<TransportConnectionEvent> _connectionChangedController = StreamController<TransportConnectionEvent>.broadcast();

  String _localPeerId = 'node-demo-user';
  Timer? _heartbeatTimer;

  final Map<String, SimulatedNode> simulatedNodes = {
    'node-vol-02': SimulatedNode(
      meshId: 'node-vol-02',
      displayName: 'Volunteer 02',
      isOnline: true,
      hopDistance: 1,
      latitude: 37.7752,
      longitude: -122.4190,
    ),
    'node-shelter-01': SimulatedNode(
      meshId: 'node-shelter-01',
      displayName: 'Shelter Node Alpha',
      isOnline: true,
      hopDistance: 2,
      latitude: 37.7765,
      longitude: -122.4175,
      isShelter: true,
    ),
    'node-rescue-gw': SimulatedNode(
      meshId: 'node-rescue-gw',
      displayName: 'Rescue Gateway HQ',
      isOnline: true,
      hopDistance: 3,
      latitude: 37.7780,
      longitude: -122.4150,
      isRescue: true,
    ),
    'node-medic-03': SimulatedNode(
      meshId: 'node-medic-03',
      displayName: 'Medic Patrol 03',
      isOnline: true,
      hopDistance: 1,
      latitude: 37.7745,
      longitude: -122.4210,
    ),
  };

  @override
  bool get isDemoMode => true;

  @override
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;

  @override
  Stream<TransportPayloadEvent> get onPayloadReceived => _payloadReceivedController.stream;

  @override
  Stream<TransportConnectionEvent> get onConnectionChanged => _connectionChangedController.stream;

  @override
  Future<bool> initialize(String localPeerId) async {
    _localPeerId = localPeerId;
    MeshLogger().log(
      MeshLogType.discovery,
      'DemoTransport',
      'SIMULATION / DEMO MODE initialized for local peer: $_localPeerId',
    );
    return true;
  }

  @override
  Future<bool> startDiscovery() async {
    MeshLogger().log(
      MeshLogType.discovery,
      'DemoTransport',
      'SIMULATION: Discovering simulated nearby nodes...',
    );

    // Emit discovered simulated peers
    for (final node in simulatedNodes.values) {
      if (node.isOnline) {
        _peerDiscoveredController.add(Peer(
          meshId: node.meshId,
          displayName: node.displayName,
          lastSeen: DateTime.now(),
          rssi: node.hopDistance == 1 ? -64 : -82,
          estimatedDistanceMeters: node.hopDistance == 1 ? 14.5 : 35.0,
          hopCount: node.hopDistance,
          isRelay: true,
          isShelterNode: node.isShelter,
          isRescueNode: node.isRescue,
          connectionState: node.hopDistance == 1 ? PeerConnectionState.connected : PeerConnectionState.discovering,
          latitude: node.latitude,
          longitude: node.longitude,
        ));
      }
    }

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      for (final node in simulatedNodes.values) {
        if (node.isOnline) {
          _peerDiscoveredController.add(Peer(
            meshId: node.meshId,
            displayName: node.displayName,
            lastSeen: DateTime.now(),
            rssi: node.hopDistance == 1 ? -65 : -80,
            hopCount: node.hopDistance,
            isRelay: true,
            isShelterNode: node.isShelter,
            isRescueNode: node.isRescue,
            connectionState: node.hopDistance == 1 ? PeerConnectionState.connected : PeerConnectionState.discovering,
            latitude: node.latitude,
            longitude: node.longitude,
          ));
        }
      }
    });

    return true;
  }

  @override
  Future<void> stopDiscovery() async {
    _heartbeatTimer?.cancel();
  }

  @override
  Future<bool> send(String peerId, List<int> payload) async {
    _simulateMultiHopDelivery(peerId, payload);
    return true;
  }

  @override
  Future<bool> broadcast(List<int> payload) async {
    for (final node in simulatedNodes.values) {
      if (node.isOnline && node.hopDistance == 1) {
        _simulateMultiHopDelivery(node.meshId, payload);
      }
    }
    return true;
  }

  void _simulateMultiHopDelivery(String targetPeerId, List<int> payloadBytes) {
    try {
      final jsonStr = utf8.decode(payloadBytes);
      final rawMsg = MeshMessage.deserialize(jsonStr);

      MeshLogger().log(
        MeshLogType.messageForwarded,
        'DemoTransport',
        'SIMULATION: Outgoing packet ${rawMsg.messageId} to $targetPeerId (Hops: ${rawMsg.hopCount})',
      );

      // If message is directed to rescue node or broadcast, simulate hop progression
      Timer(const Duration(milliseconds: 700), () {
        // Volunteer relays packet
        MeshLogger().log(
          MeshLogType.messageForwarded,
          'DemoTransport',
          'SIMULATION: [HOP 1] Volunteer 02 relayed packet ${rawMsg.messageId}',
        );

        Timer(const Duration(milliseconds: 700), () {
          // Shelter relays packet
          MeshLogger().log(
            MeshLogType.messageForwarded,
            'DemoTransport',
            'SIMULATION: [HOP 2] Shelter Node relayed packet ${rawMsg.messageId}',
          );

          Timer(const Duration(milliseconds: 800), () {
            // Rescue Gateway receives packet and responds with an ACK
            MeshLogger().log(
              MeshLogType.messageDelivered,
              'DemoTransport',
              'SIMULATION: [HOP 3] Rescue Gateway HQ DELIVERED packet ${rawMsg.messageId}',
            );

            // Construct and inject simulated ACK back to user
            final ackMsg = MeshMessage(
              protocolVersion: 1,
              messageType: MessageType.ack,
              messageId: const Uuid().v4(),
              senderId: 'node-rescue-gw',
              destinationId: _localPeerId,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              ttl: 7,
              hopCount: 3,
              payload: jsonEncode({
                'ackMessageId': rawMsg.messageId,
                'acknowledgedBy': 'Rescue Gateway HQ',
                'status': 'DELIVERED',
              }),
              nonce: const Uuid().v4(),
              relayHops: ['node-shelter-01', 'node-vol-02'],
            );

            final ackBytes = utf8.encode(ackMsg.serialize());
            _payloadReceivedController.add(TransportPayloadEvent(
              peerId: 'node-vol-02',
              bytes: ackBytes,
            ));
          });
        });
      });
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'DemoTransport', 'Simulation payload parse error: $e');
    }
  }

  void toggleNodeStatus(String nodeId, bool online) {
    if (simulatedNodes.containsKey(nodeId)) {
      simulatedNodes[nodeId]!.isOnline = online;
      _connectionChangedController.add(TransportConnectionEvent(
        peerId: nodeId,
        connected: online,
      ));
      MeshLogger().log(
        MeshLogType.routeUpdated,
        'DemoTransport',
        'SIMULATION: Node $nodeId toggled online=$online (Triggering mesh self-healing recalculation)',
      );
    }
  }

  @override
  Future<DeviceCapabilities> getCapabilities() async {
    return const DeviceCapabilities(
      bleSupported: true,
      bluetoothEnabled: true,
      advertisingSupported: true,
      wifiDirectSupported: true,
      locationPermissionGranted: true,
      nearbyDevicesPermissionGranted: true,
      batteryLevel: 88,
      powerSaveMode: false,
      platform: 'demo-sandbox',
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _peerDiscoveredController.close();
    _payloadReceivedController.close();
    _connectionChangedController.close();
  }
}
