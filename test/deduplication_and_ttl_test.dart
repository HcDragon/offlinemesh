import 'package:flutter_test/flutter_test.dart';
import 'package:meshconnect/core/errors/mesh_exception.dart';
import 'package:meshconnect/mesh/deduplication_manager.dart';
import 'package:meshconnect/mesh/ttl_manager.dart';
import 'package:meshconnect/models/mesh_message.dart';

void main() {
  group('Deduplication & Packet Loop Suppression Tests', () {
    test('Should detect and suppress duplicate packet IDs', () {
      final dedup = DeduplicationManager(capacity: 100);

      const packetId = 'packet-unique-123';
      expect(dedup.isDuplicate(packetId), isFalse); // First arrival is new
      expect(dedup.isDuplicate(packetId), isTrue);  // Duplicate arrival is suppressed
      expect(dedup.isDuplicate(packetId), isTrue);  // Triplicate arrival is suppressed
    });

    test('Should respect bounded cache capacity and evict oldest', () {
      final dedup = DeduplicationManager(capacity: 3);

      dedup.isDuplicate('id-1');
      dedup.isDuplicate('id-2');
      dedup.isDuplicate('id-3');
      expect(dedup.size, equals(3));

      // Adding id-4 should evict id-1
      dedup.isDuplicate('id-4');
      expect(dedup.size, equals(3));

      // id-1 is now evicted and treated as new if seen again
      expect(dedup.isDuplicate('id-1'), isFalse);
    });
  });

  group('TTL & Hop Count Processing Tests', () {
    final ttlManager = TtlManager();

    test('Should decrement TTL and increment hopCount during relay', () {
      final msg = MeshMessage(
        messageType: MessageType.text,
        messageId: 'msg-hop-01',
        senderId: 'node-alice',
        destinationId: 'node-bob',
        createdAt: 1774300000000,
        ttl: 5,
        hopCount: 1,
        payload: 'Test relay',
        nonce: 'nonce-1',
        relayHops: ['node-alice'],
      );

      final relayed = ttlManager.processRelayTtl(msg, 'node-relay-1');
      expect(relayed.ttl, equals(4));
      expect(relayed.hopCount, equals(2));
      expect(relayed.relayHops, contains('node-relay-1'));
    });

    test('Should throw TtlExpiredException when packet TTL reaches 1 or below', () {
      final expiredMsg = MeshMessage(
        messageType: MessageType.text,
        messageId: 'msg-expired-01',
        senderId: 'node-alice',
        destinationId: 'node-bob',
        createdAt: 1774300000000,
        ttl: 1,
        hopCount: 6,
        payload: 'Dying packet',
        nonce: 'nonce-exp',
      );

      expect(
        () => ttlManager.processRelayTtl(expiredMsg, 'node-relay-final'),
        throwsA(isA<TtlExpiredException>()),
      );
    });

    test('Should provide priority-matched initial TTLs', () {
      expect(ttlManager.getInitialTtl(MessagePriority.emergency), equals(15));
      expect(ttlManager.getInitialTtl(MessagePriority.high), equals(10));
      expect(ttlManager.getInitialTtl(MessagePriority.normal), equals(7));
    });
  });
}
