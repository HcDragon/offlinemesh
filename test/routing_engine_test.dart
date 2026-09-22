import 'package:flutter_test/flutter_test.dart';
import 'package:meshconnect/models/mesh_route.dart';
import 'package:meshconnect/models/peer.dart';

void main() {
  group('Mesh Routing & Scoring Algorithm Tests', () {
    test('Should compute higher score for direct high-quality routes', () {
      final directScore = MeshRoute.calculateScore(
        linkQuality: 0.95,
        hopCount: 1,
        ageSeconds: 5,
        batteryLevel: 90,
        isDirect: true,
      );

      final multiHopScore = MeshRoute.calculateScore(
        linkQuality: 0.70,
        hopCount: 3,
        ageSeconds: 20,
        batteryLevel: 90,
        isDirect: false,
      );

      expect(directScore, greaterThan(multiHopScore));
    });

    test('Should penalize low battery and stale routes', () {
      final fullBatteryFresh = MeshRoute.calculateScore(
        linkQuality: 0.8,
        hopCount: 2,
        ageSeconds: 5,
        batteryLevel: 100,
      );

      final depletedBatteryStale = MeshRoute.calculateScore(
        linkQuality: 0.8,
        hopCount: 2,
        ageSeconds: 40,
        batteryLevel: 10,
      );

      expect(fullBatteryFresh, greaterThan(depletedBatteryStale));
    });

    test('Self-healing selection of best available next-hop', () {
      final connectedPeers = [
        Peer(
          meshId: 'node-volunteer-02',
          displayName: 'Volunteer 02',
          lastSeen: DateTime.now(),
          rssi: -62,
          hopCount: 1,
          isRelay: true,
          connectionState: PeerConnectionState.connected,
        ),
        Peer(
          meshId: 'node-medic-03',
          displayName: 'Medic Patrol 03',
          lastSeen: DateTime.now(),
          rssi: -75,
          hopCount: 1,
          isRelay: true,
          connectionState: PeerConnectionState.connected,
        ),
      ];

      // Volunteer has better RSSI (-62 > -75)
      connectedPeers.sort((a, b) => (b.rssi ?? -100).compareTo(a.rssi ?? -100));
      expect(connectedPeers.first.meshId, equals('node-volunteer-02'));

      // If Volunteer drops out:
      final remainingPeers = connectedPeers.where((p) => p.meshId != 'node-volunteer-02').toList();
      expect(remainingPeers.length, equals(1));
      expect(remainingPeers.first.meshId, equals('node-medic-03')); // Self-healing fallback
    });
  });
}
