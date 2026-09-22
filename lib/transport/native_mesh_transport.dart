import 'dart:async';
import 'package:flutter/services.dart';
import '../core/logging/mesh_logger.dart';
import '../models/device_capabilities.dart';
import '../models/peer.dart';
import 'mesh_transport.dart';

class NativeMeshTransport implements MeshTransport {
  static const MethodChannel _methodChannel = MethodChannel('com.meshconnect/transport');
  static const EventChannel _eventChannel = EventChannel('com.meshconnect/events');

  final StreamController<Peer> _peerDiscoveredController = StreamController<Peer>.broadcast();
  final StreamController<TransportPayloadEvent> _payloadReceivedController = StreamController<TransportPayloadEvent>.broadcast();
  final StreamController<TransportConnectionEvent> _connectionChangedController = StreamController<TransportConnectionEvent>.broadcast();

  StreamSubscription? _eventSubscription;
  bool _initialized = false;

  @override
  bool get isDemoMode => false;

  @override
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;

  @override
  Stream<TransportPayloadEvent> get onPayloadReceived => _payloadReceivedController.stream;

  @override
  Stream<TransportConnectionEvent> get onConnectionChanged => _connectionChangedController.stream;

  @override
  Future<bool> initialize(String localPeerId) async {
    try {
      _startListeningEvents();
      final result = await _methodChannel.invokeMethod<bool>('initialize', {
        'peerId': localPeerId,
      });
      _initialized = result ?? false;
      MeshLogger().log(
        MeshLogType.discovery,
        'NativeTransport',
        'Native MeshTransport initialized with peerId: $localPeerId',
      );
      return _initialized;
    } catch (e) {
      MeshLogger().log(
        MeshLogType.error,
        'NativeTransport',
        'Failed to initialize native transport: $e',
      );
      return false;
    }
  }

  void _startListeningEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final type = event['type'] as String?;
          final data = event['data'] as Map<dynamic, dynamic>?;

          if (type == 'peerDiscovered' && data != null) {
            final peer = Peer(
              meshId: data['peerId'] as String? ?? 'node-unknown',
              displayName: data['deviceName'] as String? ?? 'Nearby Peer',
              lastSeen: DateTime.now(),
              rssi: data['rssi'] as int?,
              connectionState: PeerConnectionState.discovering,
            );
            _peerDiscoveredController.add(peer);
          } else if (type == 'payloadReceived' && data != null) {
            final peerId = data['peerId'] as String? ?? '';
            final payload = (data['payload'] as List<dynamic>?)?.cast<int>() ?? [];
            _payloadReceivedController.add(TransportPayloadEvent(
              peerId: peerId,
              bytes: payload,
            ));
          } else if ((type == 'peerConnected' || type == 'peerDisconnected') && data != null) {
            final peerId = data['peerId'] as String? ?? '';
            final connected = type == 'peerConnected';
            _connectionChangedController.add(TransportConnectionEvent(
              peerId: peerId,
              connected: connected,
            ));
          }
        }
      },
      onError: (dynamic error) {
        MeshLogger().log(
          MeshLogType.error,
          'NativeTransport',
          'Native event stream error: $error',
        );
      },
    );
  }

  @override
  Future<bool> startDiscovery() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('startDiscovery');
      return res ?? false;
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'NativeTransport', 'startDiscovery error: $e');
      return false;
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _methodChannel.invokeMethod<void>('stopDiscovery');
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'NativeTransport', 'stopDiscovery error: $e');
    }
  }

  @override
  Future<bool> send(String peerId, List<int> payload) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('send', {
        'peerId': peerId,
        'payload': payload,
      });
      return res ?? false;
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'NativeTransport', 'send error: $e');
      return false;
    }
  }

  @override
  Future<bool> broadcast(List<int> payload) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('broadcast', {
        'payload': payload,
      });
      return res ?? false;
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'NativeTransport', 'broadcast error: $e');
      return false;
    }
  }

  @override
  Future<DeviceCapabilities> getCapabilities() async {
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getCapabilities');
      if (res != null) {
        return DeviceCapabilities.fromMap(res);
      }
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'NativeTransport', 'getCapabilities error: $e');
    }
    return const DeviceCapabilities();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _peerDiscoveredController.close();
    _payloadReceivedController.close();
    _connectionChangedController.close();
  }
}
