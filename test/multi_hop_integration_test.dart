import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshconnect/core/constants/app_constants.dart';
import 'package:meshconnect/crypto/crypto_service.dart';
import 'package:meshconnect/mesh/deduplication_manager.dart';
import 'package:meshconnect/mesh/ttl_manager.dart';
import 'package:meshconnect/models/mesh_message.dart';
import 'package:meshconnect/models/message_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final crypto = CryptoService();
  final ttlManager = TtlManager();
  final dedupManager = DeduplicationManager();

  group('Multi-Hop Mesh Integration Simulation (A → B → C → Rescue Gateway)', () {
    test('Simulates end-to-end multi-hop packet dispatch and ACK return', () async {
      // 1. Setup Identities
      final nodeAKey = await crypto.generateIdentityKeyPair();
      const nodeAId = 'node-A-user';
      const nodeBId = 'node-B-volunteer';
      const nodeCId = 'node-C-shelter';
      const nodeRescueId = 'node-rescue-gw';

      // 2. Node A creates & encrypts message
      const textMessage = 'Medic team needed urgently at Sector 4.';
      final broadcastKey = await crypto.getEmergencyBroadcastKey();
      final ciphertext = await crypto.encryptPayload(
        plainText: textMessage,
        secretKey: broadcastKey,
      );

      final signature = await crypto.signMessage(
        data: 'msg-sim-01:$nodeAId:$nodeRescueId:$ciphertext:nonce-1',
        keyPair: nodeAKey.signingKeyPair,
      );

      var packet = MeshMessage(
        protocolVersion: AppConstants.protocolVersion,
        messageType: MessageType.text,
        messageId: 'msg-sim-01',
        senderId: nodeAId,
        destinationId: nodeRescueId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        ttl: 7,
        hopCount: 0,
        priority: MessagePriority.high,
        payload: ciphertext,
        signature: signature,
        nonce: 'nonce-1',
        status: MessageStatus.queued,
        relayHops: [nodeAId],
      );

      expect(packet.hopCount, equals(0));
      expect(packet.ttl, equals(7));

      // 3. Node B (Volunteer) receives packet: Dedup check + TTL relay
      expect(dedupManager.isDuplicate(packet.messageId), isFalse);
      packet = ttlManager.processRelayTtl(packet, nodeBId);
      expect(packet.hopCount, equals(1));
      expect(packet.ttl, equals(6));
      expect(packet.relayHops, equals([nodeAId, nodeBId]));

      // 4. Node C (Shelter) receives packet: Dedup check + TTL relay
      packet = ttlManager.processRelayTtl(packet, nodeCId);
      expect(packet.hopCount, equals(2));
      expect(packet.ttl, equals(5));
      expect(packet.relayHops, equals([nodeAId, nodeBId, nodeCId]));

      // 5. Node D (Rescue Gateway) receives packet as final destination!
      expect(packet.destinationId, equals(nodeRescueId));
      expect(packet.hopCount, equals(2)); // Arrived after 2 intermediate relays

      // Rescue Gateway verifies signature
      final nodeAPubKey = base64Encode(nodeAKey.signingPublicKey.bytes);
      final sigValid = await crypto.verifySignature(
        data: '${packet.messageId}:${packet.senderId}:${packet.destinationId}:${packet.payload}:${packet.nonce}',
        signatureBase64: packet.signature,
        publicKeyBase64: nodeAPubKey,
      );
      expect(sigValid, isTrue);

      // Rescue Gateway decrypts payload
      final decryptedText = await crypto.decryptPayload(
        encryptedJson: packet.payload,
        secretKey: broadcastKey,
      );
      expect(decryptedText, equals(textMessage));

      // 6. Rescue Gateway dispatches ACK packet back to Node A
      final ackPayload = jsonEncode({
        'ackMessageId': packet.messageId,
        'acknowledgedBy': 'Rescue Gateway HQ',
        'status': 'DELIVERED',
      });

      final ackPacket = MeshMessage(
        protocolVersion: AppConstants.protocolVersion,
        messageType: MessageType.ack,
        messageId: 'ack-sim-01',
        senderId: nodeRescueId,
        destinationId: nodeAId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        ttl: 7,
        hopCount: 2,
        priority: MessagePriority.high,
        payload: ackPayload,
        nonce: 'nonce-ack-1',
        status: MessageStatus.delivered,
        relayHops: [nodeRescueId, nodeCId, nodeBId],
      );

      expect(ackPacket.messageType, equals(MessageType.ack));
      expect(ackPacket.destinationId, equals(nodeAId));
    });
  });
}
