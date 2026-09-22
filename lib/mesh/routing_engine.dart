import '../core/constants/app_constants.dart';
import '../core/logging/mesh_logger.dart';
import '../models/mesh_route.dart';
import '../models/peer.dart';
import '../storage/route_repository.dart';

class RoutingEngine {
  final RouteRepository _routeRepository;
  final Map<String, List<MeshRoute>> _routingTable = {}; // destinationId -> list of routes

  RoutingEngine([RouteRepository? routeRepository])
      : _routeRepository = routeRepository ?? RouteRepository();

  Map<String, List<MeshRoute>> get routes => Map.unmodifiable(_routingTable);

  Future<void> updateRoute({
    required String sourceId,
    required String destinationId,
    required String nextHopId,
    required int hopCount,
    required double linkQuality,
    required int localBatteryLevel,
  }) async {
    final score = MeshRoute.calculateScore(
      linkQuality: linkQuality,
      hopCount: hopCount,
      ageSeconds: 0,
      batteryLevel: localBatteryLevel,
      isDirect: hopCount == 1,
    );

    final route = MeshRoute(
      sourceId: sourceId,
      destinationId: destinationId,
      nextHopId: nextHopId,
      hopCount: hopCount,
      score: score,
      lastUpdated: DateTime.now(),
      linkQuality: linkQuality,
    );

    final currentRoutes = _routingTable[destinationId] ?? [];
    currentRoutes.removeWhere((r) => r.nextHopId == nextHopId);
    currentRoutes.add(route);
    currentRoutes.sort((a, b) => b.score.compareTo(a.score));
    _routingTable[destinationId] = currentRoutes;

    await _routeRepository.upsertRoute(route);

    MeshLogger().log(
      MeshLogType.routeUpdated,
      'RoutingEngine',
      'Route updated for dst=$destinationId via nextHop=$nextHopId, score=${score.toStringAsFixed(1)}, hops=$hopCount',
    );
  }

  /// Self-healing mesh: called when a node drops or link breaks
  Future<void> invalidateNextHop(String brokenPeerId) async {
    bool changed = false;
    for (final dst in _routingTable.keys) {
      final list = _routingTable[dst] ?? [];
      final beforeCount = list.length;
      list.removeWhere((r) => r.nextHopId == brokenPeerId);
      if (list.length != beforeCount) {
        changed = true;
        await _routeRepository.deleteRoute(dst, brokenPeerId);
      }
    }

    if (changed) {
      MeshLogger().log(
        MeshLogType.routeUpdated,
        'RoutingEngine',
        'Self-healing triggered: Invalidation of broken peer $brokenPeerId complete',
      );
    }
  }

  /// Selects optimal candidate next hop for a given destination
  MeshRoute? findBestNextHop(String destinationId, List<Peer> activeConnectedPeers) {
    final candidateRoutes = _routingTable[destinationId];
    if (candidateRoutes != null && candidateRoutes.isNotEmpty) {
      // Find highest score route where nextHop is currently among active connected peers
      for (final r in candidateRoutes) {
        if (!r.isStale && activeConnectedPeers.any((p) => p.meshId == r.nextHopId)) {
          return r;
        }
      }
    }

    // Direct fallback: is destination directly connected?
    final direct = activeConnectedPeers.where((p) => p.meshId == destinationId);
    if (direct.isNotEmpty) {
      return MeshRoute(
        sourceId: 'local',
        destinationId: destinationId,
        nextHopId: destinationId,
        hopCount: 1,
        score: 100.0,
        lastUpdated: DateTime.now(),
      );
    }

    // Secondary fallback: select the best connected relay peer
    if (activeConnectedPeers.isNotEmpty) {
      final relays = activeConnectedPeers.where((p) => p.isRelay).toList();
      final pool = relays.isNotEmpty ? relays : activeConnectedPeers;
      // pick peer with best RSSI
      pool.sort((a, b) => (b.rssi ?? -100).compareTo(a.rssi ?? -100));
      final bestRelay = pool.first;
      return MeshRoute(
        sourceId: 'local',
        destinationId: destinationId,
        nextHopId: bestRelay.meshId,
        hopCount: 2,
        score: 45.0,
        lastUpdated: DateTime.now(),
      );
    }

    return null;
  }

  Future<void> purgeStaleRoutes() async {
    final now = DateTime.now();
    for (final dst in _routingTable.keys) {
      _routingTable[dst]?.removeWhere((r) =>
        now.difference(r.lastUpdated).inSeconds > AppConstants.staleRouteThresholdSeconds
      );
    }
    await _routeRepository.purgeStaleRoutes(AppConstants.staleRouteThresholdSeconds);
  }
}
