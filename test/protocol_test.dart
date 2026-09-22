import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshconnect/models/mesh_message.dart';
import 'package:meshconnect/models/message_status.dart';

void main() {
  group('Mesh Protocol Wire Format & Serialization Tests', () {
    test('Should correctly serialize and deserialize a MeshMessage packet', () {
      final original = MeshMessage(
        protocolVersion: 1,
        messageType: MessageType.text,
        messageId: 'msg-test-1001',
        senderId: 'node-alice',
        destinationId: 'node-bob',
        createdAt: 1774300000000,
        ttl: 7,
        hopCount: 1,
        priority: MessagePriority.normal,
        payload: 'EncryptedPayloadData12345',
        signature: 'SignatureBase64StringABC',
        nonce: 'nonce-uuid-999',
        status: MessageStatus.relayed,
        relayHops: ['node-alice', 'node-relay-1'],
      );

      final wireJson = original.serialize();
      expect(wireJson, isA<String>());

      final wireMap = jsonDecode(wireJson) as Map<String, dynamic>;
      expect(wireMap['v'], equals(1));
      expect(wireMap['type'], equals('text'));
      expect(wireMap['id'], equals('msg-test-1001'));
      expect(wireMap['src'], equals('node-alice'));
      expect(wireMap['dst'], equals('node-bob'));
      expect(wireMap['ttl'], equals(7));
      expect(wireMap['hops'], equals(1));
      expect(wireMap['prio'], equals('normal'));
      expect(wireMap['data'], equals('EncryptedPayloadData12345'));
      expect(wireMap['sig'], equals('SignatureBase64StringABC'));
      expect(wireMap['nonce'], equals('nonce-uuid-999'));
      expect(wireMap['relays'], contains('node-relay-1'));

      final restored = MeshMessage.deserialize(wireJson);
      expect(restored.messageId, equals(original.messageId));
      expect(restored.senderId, equals(original.senderId));
      expect(restored.destinationId, equals(original.destinationId));
      expect(restored.ttl, equals(original.ttl));
      expect(restored.hopCount, equals(original.hopCount));
      expect(restored.payload, equals(original.payload));
      expect(restored.signature, equals(original.signature));
      expect(restored.nonce, equals(original.nonce));
      expect(restored.relayHops, equals(original.relayHops));
    });

    test('Should handle broadcast and SOS priorities properly', () {
      final broadcastMsg = MeshMessage(
        messageType: MessageType.sos,
        messageId: 'sos-999',
        senderId: 'node-victim',
        destinationId: '*',
        createdAt: 1774300000000,
        ttl: 15,
        priority: MessagePriority.emergency,
        payload: 'EMERGENCY: Assistance needed!',
        nonce: 'nonce-sos-1',
      );

      expect(broadcastMsg.isBroadcast, isTrue);
      expect(broadcastMsg.isSos, isTrue);
      expect(broadcastMsg.ttl, equals(15));
    });

    test('Should correctly convert DB map records', () {
      final msg = MeshMessage(
        messageType: MessageType.location,
        messageId: 'msg-loc-01',
        senderId: 'node-alice',
        destinationId: 'node-bob',
        createdAt: 1774300050000,
        ttl: 5,
        hopCount: 2,
        priority: MessagePriority.high,
        payload: '{"lat":37.7749,"lng":-122.4194}',
        signature: 'sig123',
        nonce: 'nonce-loc-1',
        status: MessageStatus.delivered,
        relayHops: ['node-alice', 'node-charlie'],
      );

      final dbMap = msg.toDbMap();
      final restoredFromDb = MeshMessage.fromDbMap(dbMap);

      expect(restoredFromDb.messageId, equals(msg.messageId));
      expect(restoredFromDb.messageType, equals(MessageType.location));
      expect(restoredFromDb.status, equals(MessageStatus.delivered));
      expect(restoredFromDb.relayHops.length, equals(2));
    });
  });
}
