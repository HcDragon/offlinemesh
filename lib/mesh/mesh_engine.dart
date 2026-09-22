import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/mesh_logger.dart';
import '../crypto/crypto_service.dart';
import '../crypto/key_manager.dart';
import '../models/mesh_message.dart';
import '../models/message_status.dart';
import '../models/sos_event.dart';
import '../storage/message_repository.dart';
import '../storage/sos_repository.dart';
import '../transport/transport_manager.dart';
import 'ack_manager.dart';
import 'deduplication_manager.dart';
import 'message_forwarder.dart';
import 'peer_manager.dart';
import 'routing_engine.dart';
import 'ttl_manager.dart';

class MeshEngine extends ChangeNotifier {
  static final MeshEngine _instance = MeshEngine._internal();
  factory MeshEngine() => _instance;
  MeshEngine._internal();

  final KeyManager _keyManager = KeyManager();
  final CryptoService _cryptoService = CryptoService();
  final DeduplicationManager _deduplicationManager = DeduplicationManager();
  final TtlManager _ttlManager = TtlManager();
  final PeerManager peerManager = PeerManager();
  final RoutingEngine routingEngine = RoutingEngine();
  final MessageRepository messageRepository = MessageRepository();
  final SosRepository sosRepository = SosRepository();
  final AckManager ackManager = AckManager();

  late final MessageForwarder messageForwarder;
  final TransportManager transportManager = TransportManager();

  StreamSubscription? _transportPayloadSub;
  StreamSubscription? _transportPeerSub;
  StreamSubscription? _transportConnSub;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String get localPeerId => _keyManager.meshId;
  String get localDisplayName => _keyManager.displayName;

  Future<void> initialize({bool startInDemoMode = false}) async {
    if (_isInitialized) return;

    await _keyManager.initialize();
    await peerManager.loadPersistedPeers();

    messageForwarder = MessageForwarder(
      messageRepository: messageRepository,
      routingEngine: routingEngine,
      peerManager: peerManager,
    );

    messageForwarder.onSendPayload = (nextHopId, bytes) async {
      return await transportManager.activeTransport.send(nextHopId, bytes);
    };

    messageForwarder.onBroadcast = (bytes) async {
      return await transportManager.activeTransport.broadcast(bytes);
    };

    await transportManager.initialize(_keyManager.meshId, startInDemoMode: startInDemoMode);
    _bindTransportEvents();

    await transportManager.activeTransport.startDiscovery();
    _isInitialized = true;

    MeshLogger().log(
      MeshLogType.discovery,
      'MeshEngine',
      'MeshEngine initialized for node: ${_keyManager.meshId} (${_keyManager.displayName})',
    );
    notifyListeners();
  }

  void _bindTransportEvents() {
    _transportPayloadSub?.cancel();
    _transportPeerSub?.cancel();
    _transportConnSub?.cancel();

    final transport = transportManager.activeTransport;

    _transportPeerSub = transport.onPeerDiscovered.listen((peer) {
      peerManager.handlePeerDiscovered(peer);
      // Auto-update route for direct peer
      routingEngine.updateRoute(
        sourceId: localPeerId,
        destinationId: peer.meshId,
        nextHopId: peer.meshId,
        hopCount: peer.hopCount,
        linkQuality: 0.9,
        localBatteryLevel: 100,
      );
      messageForwarder.triggerImmediateFlush();
      notifyListeners();
    });

    _transportConnSub = transport.onConnectionChanged.listen((event) {
      peerManager.updateConnectionState(event.peerId, event.connected);
      if (!event.connected) {
        routingEngine.invalidateNextHop(event.peerId);
      } else {
        messageForwarder.triggerImmediateFlush();
      }
      notifyListeners();
    });

    _transportPayloadSub = transport.onPayloadReceived.listen((event) {
      _processIncomingRawPayload(event.peerId, event.bytes);
    });
  }

  Future<void> switchMode(bool useDemoMode) async {
    await transportManager.setDemoMode(useDemoMode);
    _bindTransportEvents();
    await transportManager.activeTransport.startDiscovery();
    notifyListeners();
  }

  /// Inbound packet pipeline
  Future<void> _processIncomingRawPayload(String fromPeerId, List<int> rawBytes) async {
    try {
      final jsonStr = utf8.decode(rawBytes);
      final message = MeshMessage.deserialize(jsonStr);

      // 1. Replay & Duplicate Suppression
      if (_deduplicationManager.isDuplicate(message.messageId)) {
        return;
      }

      // Check timestamp window (within 24 hours)
      final ageMs = DateTime.now().millisecondsSinceEpoch - message.createdAt;
      if (ageMs > 86400000 || ageMs < -600000) {
        MeshLogger().log(MeshLogType.error, 'MeshEngine', 'Replay check failed: timestamp out of bounds');
        return;
      }

      MeshLogger().log(
        MeshLogType.messageDelivered,
        'MeshEngine',
        'Incoming packet ${message.messageId} from $fromPeerId (Type: ${message.messageType.name}, Hops: ${message.hopCount})',
      );

      // 2. Is this node the final destination or is it a broadcast?
      final isForMe = message.destinationId == localPeerId || message.isBroadcast;

      if (isForMe) {
        await _handleMessageForLocalNode(message);
      }

      // 3. If it's a broadcast or destined for another node, relay it
      if (!isForMe || message.isBroadcast) {
        await _relayMessage(message);
      }
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'MeshEngine', 'Failed to process packet: $e');
    }
  }

  Future<void> _handleMessageForLocalNode(MeshMessage message) async {
    String readablePayload = message.payload;

    // Decrypt if it's an encrypted text or SOS payload
    if (message.messageType == MessageType.text || message.messageType == MessageType.sos) {
      try {
        final key = await _cryptoService.getEmergencyBroadcastKey();
        readablePayload = await _cryptoService.decryptPayload(
          encryptedJson: message.payload,
          secretKey: key,
        );
      } catch (_) {
        // May already be plaintext JSON or formatted
        readablePayload = message.payload;
      }
    }

    final receivedMessage = message.copyWith(
      status: MessageStatus.delivered,
      payload: readablePayload,
    );

    await messageRepository.insertMessage(receivedMessage);

    // If it's an ACK packet, resolve it
    if (message.messageType == MessageType.ack) {
      await ackManager.handleIncomingAck(message);
      notifyListeners();
      return;
    }

    // If it's an SOS packet, record emergency event
    if (message.messageType == MessageType.sos) {
      Map<String, dynamic> sosData = {};
      try {
        sosData = jsonDecode(readablePayload) as Map<String, dynamic>;
      } catch (_) {}

      final event = SosEvent(
        sosId: message.messageId,
        originPeerId: message.senderId,
        originDisplayName: sosData['originName'] as String? ?? 'Peer ${message.senderId.substring(0, 4)}',
        timestamp: DateTime.fromMillisecondsSinceEpoch(message.createdAt),
        latitude: (sosData['lat'] as num?)?.toDouble(),
        longitude: (sosData['lng'] as num?)?.toDouble(),
        emergencyNote: sosData['note'] as String? ?? 'Emergency SOS Alert',
        relayHistory: message.relayHops,
      );
      await sosRepository.upsertSosEvent(event);
      MeshLogger().log(MeshLogType.sosCreated, 'MeshEngine', 'Emergency SOS event recorded: ${event.sosId}');
    }

    // Send ACK back if it is a 1-to-1 message
    if (!message.isBroadcast && message.messageType != MessageType.ack) {
      final ack = ackManager.createAckMessage(
        originalMessage: message,
        localPeerId: localPeerId,
      );
      await _dispatchPacket(ack);
    }

    notifyListeners();
  }

  Future<void> _relayMessage(MeshMessage message) async {
    try {
      final relayedMessage = _ttlManager.processRelayTtl(message, localPeerId);
      MeshLogger().log(
        MeshLogType.messageForwarded,
        'MeshEngine',
        'Relaying message ${relayedMessage.messageId} (New TTL: ${relayedMessage.ttl}, Hops: ${relayedMessage.hopCount})',
      );
      await _dispatchPacket(relayedMessage);
    } catch (e) {
      MeshLogger().log(MeshLogType.messageDuplicate, 'MeshEngine', 'Relay stopped: $e');
    }
  }

  /// Sends a user chat message through the mesh
  Future<MeshMessage> sendChatMessage({
    required String destinationId,
    required String text,
    MessagePriority priority = MessagePriority.normal,
  }) async {
    final messageId = const Uuid().v4();
    final nonce = const Uuid().v4();

    // Encrypt payload with AES-256-GCM
    final key = await _cryptoService.getEmergencyBroadcastKey();
    final encryptedPayload = await _cryptoService.encryptPayload(
      plainText: text,
      secretKey: key,
    );

    // Sign with Ed25519
    String signature = '';
    if (_keyManager.signingKeyPair != null) {
      signature = await _cryptoService.signMessage(
        data: '$messageId:$localPeerId:$destinationId:$encryptedPayload:$nonce',
        keyPair: _keyManager.signingKeyPair!,
      );
    }

    final message = MeshMessage(
      protocolVersion: AppConstants.protocolVersion,
      messageType: MessageType.text,
      messageId: messageId,
      senderId: localPeerId,
      destinationId: destinationId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      ttl: _ttlManager.getInitialTtl(priority),
      priority: priority,
      payload: encryptedPayload,
      signature: signature,
      nonce: nonce,
      status: MessageStatus.queued,
      relayHops: [localPeerId],
    );

    // Save locally
    await messageRepository.insertMessage(message.copyWith(payload: text));

    // Register pending ACK
    if (!message.isBroadcast) {
      ackManager.registerPendingMessage(messageId);
    }

    // Dispatch
    await _dispatchPacket(message);
    notifyListeners();
    return message;
  }

  /// Broadcasts an Emergency SOS with GPS coordinates and highest priority
  Future<MeshMessage> broadcastSos({
    double? latitude,
    double? longitude,
    String emergencyNote = 'EMERGENCY: Assistance needed!',
  }) async {
    final messageId = const Uuid().v4();
    final nonce = const Uuid().v4();

    final sosPayloadData = jsonEncode({
      'originName': localDisplayName,
      'lat': latitude,
      'lng': longitude,
      'note': emergencyNote,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final key = await _cryptoService.getEmergencyBroadcastKey();
    final encryptedPayload = await _cryptoService.encryptPayload(
      plainText: sosPayloadData,
      secretKey: key,
    );

    final message = MeshMessage(
      protocolVersion: AppConstants.protocolVersion,
      messageType: MessageType.sos,
      messageId: messageId,
      senderId: localPeerId,
      destinationId: '*', // Broadcast to all
      createdAt: DateTime.now().millisecondsSinceEpoch,
      ttl: AppConstants.sosTtl,
      priority: MessagePriority.emergency,
      payload: encryptedPayload,
      nonce: nonce,
      status: MessageStatus.relayed,
      relayHops: [localPeerId],
    );

    // Record local SOS event
    final event = SosEvent(
      sosId: messageId,
      originPeerId: localPeerId,
      originDisplayName: localDisplayName,
      timestamp: DateTime.now(),
      status: SosStatus.active,
      latitude: latitude,
      longitude: longitude,
      emergencyNote: emergencyNote,
      relayHistory: [localPeerId],
    );
    await sosRepository.upsertSosEvent(event);
    await messageRepository.insertMessage(message.copyWith(payload: sosPayloadData));

    MeshLogger().log(
      MeshLogType.sosCreated,
      'MeshEngine',
      '🚨 EMERGENCY SOS BROADCAST INITIATED ($messageId)',
    );

    await _dispatchPacket(message);
    notifyListeners();
    return message;
  }

  Future<void> _dispatchPacket(MeshMessage message) async {
    final bytes = utf8.encode(message.serialize());

    if (message.isBroadcast) {
      final success = await transportManager.activeTransport.broadcast(bytes);
      if (success) {
        await messageRepository.updateMessageStatus(message.messageId, MessageStatus.relayed);
      }
      return;
    }

    final bestRoute = routingEngine.findBestNextHop(message.destinationId, peerManager.connectedPeers);
    if (bestRoute != null) {
      final success = await transportManager.activeTransport.send(bestRoute.nextHopId, bytes);
      if (success) {
        await messageRepository.updateMessageStatus(message.messageId, MessageStatus.relaying);
      }
    } else {
      // Store and forward: queue locally
      MeshLogger().log(
        MeshLogType.messageQueued,
        'MeshEngine',
        'No immediate route for ${message.destinationId}; packet queued locally for store-and-forward',
      );
    }
  }

  @override
  void dispose() {
    _transportPayloadSub?.cancel();
    _transportPeerSub?.cancel();
    _transportConnSub?.cancel();
    messageForwarder.dispose();
    peerManager.dispose();
    super.dispose();
  }
}
