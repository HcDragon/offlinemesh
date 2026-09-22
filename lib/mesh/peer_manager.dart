import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/mesh_logger.dart';
import '../models/peer.dart';
import '../storage/peer_repository.dart';

class PeerManager extends ChangeNotifier {
  final PeerRepository _peerRepository;
  final Map<String, Peer> _peers = {};
  Timer? _pruneTimer;

  PeerManager([PeerRepository? peerRepository])
      : _peerRepository = peerRepository ?? PeerRepository() {
    _pruneTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkPeerTimeouts());
  }

  List<Peer> get allPeers => _peers.values.toList();
  List<Peer> get connectedPeers => _peers.values.where((p) => p.connectionState == PeerConnectionState.connected).toList();
  List<Peer> get nearbyPeers => _peers.values.toList();

  Future<void> loadPersistedPeers() async {
    final persisted = await _peerRepository.getAllPeers();
    for (final p in persisted) {
      _peers[p.meshId] = p;
    }
    notifyListeners();
  }

  Future<void> handlePeerDiscovered(Peer peer) async {
    final existing = _peers[peer.meshId];
    final updated = (existing != null)
        ? existing.copyWith(
            lastSeen: DateTime.now(),
            rssi: peer.rssi ?? existing.rssi,
            estimatedDistanceMeters: peer.estimatedDistanceMeters ?? existing.estimatedDistanceMeters,
            connectionState: PeerConnectionState.connected,
          )
        : peer.copyWith(
            connectionState: PeerConnectionState.connected,
            lastSeen: DateTime.now(),
          );

    _peers[peer.meshId] = updated;
    await _peerRepository.upsertPeer(updated);

    MeshLogger().log(
      MeshLogType.discovery,
      'PeerManager',
      'Discovered peer: ${updated.displayName} (${updated.meshId}), RSSI: ${updated.rssi} dBm',
    );
    notifyListeners();
  }

  Future<void> updateConnectionState(String meshId, bool connected) async {
    final peer = _peers[meshId];
    if (peer != null) {
      final updated = peer.copyWith(
        connectionState: connected ? PeerConnectionState.connected : PeerConnectionState.disconnected,
        lastSeen: DateTime.now(),
      );
      _peers[meshId] = updated;
      await _peerRepository.upsertPeer(updated);

      MeshLogger().log(
        connected ? MeshLogType.peerConnected : MeshLogType.peerDisconnected,
        'PeerManager',
        'Peer ${peer.displayName} is now ${connected ? "CONNECTED" : "DISCONNECTED"}',
      );
      notifyListeners();
    }
  }

  void _checkPeerTimeouts() {
    final now = DateTime.now();
    bool changed = false;

    for (final peer in _peers.values) {
      if (peer.connectionState == PeerConnectionState.connected) {
        final age = now.difference(peer.lastSeen).inSeconds;
        if (age > AppConstants.peerTimeoutSeconds) {
          _peers[peer.meshId] = peer.copyWith(
            connectionState: PeerConnectionState.disconnected,
          );
          changed = true;
          _peerRepository.updatePeerConnectionState(peer.meshId, PeerConnectionState.disconnected);
        }
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  Peer? getPeer(String meshId) => _peers[meshId];

  @override
  void dispose() {
    _pruneTimer?.cancel();
    super.dispose();
  }
}
