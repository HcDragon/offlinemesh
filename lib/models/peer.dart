enum PeerConnectionState {
  discovering,
  connected,
  disconnected,
}

class Peer {
  final String meshId;
  final String displayName;
  final String publicKey;
  final DateTime lastSeen;
  final int? rssi;
  final double? estimatedDistanceMeters;
  final int hopCount;
  final bool isRelay;
  final bool isSosNode;
  final bool isShelterNode;
  final bool isRescueNode;
  final PeerConnectionState connectionState;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> metadata;

  const Peer({
    required this.meshId,
    required this.displayName,
    this.publicKey = '',
    required this.lastSeen,
    this.rssi,
    this.estimatedDistanceMeters,
    this.hopCount = 1,
    this.isRelay = true,
    this.isSosNode = false,
    this.isShelterNode = false,
    this.isRescueNode = false,
    this.connectionState = PeerConnectionState.discovering,
    this.latitude,
    this.longitude,
    this.metadata = const {},
  });

  Peer copyWith({
    String? meshId,
    String? displayName,
    String? publicKey,
    DateTime? lastSeen,
    int? rssi,
    double? estimatedDistanceMeters,
    int? hopCount,
    bool? isRelay,
    bool? isSosNode,
    bool? isShelterNode,
    bool? isRescueNode,
    PeerConnectionState? connectionState,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) {
    return Peer(
      meshId: meshId ?? this.meshId,
      displayName: displayName ?? this.displayName,
      publicKey: publicKey ?? this.publicKey,
      lastSeen: lastSeen ?? this.lastSeen,
      rssi: rssi ?? this.rssi,
      estimatedDistanceMeters: estimatedDistanceMeters ?? this.estimatedDistanceMeters,
      hopCount: hopCount ?? this.hopCount,
      isRelay: isRelay ?? this.isRelay,
      isSosNode: isSosNode ?? this.isSosNode,
      isShelterNode: isShelterNode ?? this.isShelterNode,
      isRescueNode: isRescueNode ?? this.isRescueNode,
      connectionState: connectionState ?? this.connectionState,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meshId': meshId,
      'displayName': displayName,
      'publicKey': publicKey,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'rssi': rssi,
      'estimatedDistanceMeters': estimatedDistanceMeters,
      'hopCount': hopCount,
      'isRelay': isRelay ? 1 : 0,
      'isSosNode': isSosNode ? 1 : 0,
      'isShelterNode': isShelterNode ? 1 : 0,
      'isRescueNode': isRescueNode ? 1 : 0,
      'connectionState': connectionState.name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Peer.fromMap(Map<String, dynamic> map) {
    return Peer(
      meshId: map['meshId'] as String,
      displayName: map['displayName'] as String? ?? 'Peer',
      publicKey: map['publicKey'] as String? ?? '',
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      rssi: map['rssi'] as int?,
      estimatedDistanceMeters: (map['estimatedDistanceMeters'] as num?)?.toDouble(),
      hopCount: map['hopCount'] as int? ?? 1,
      isRelay: (map['isRelay'] as int? ?? 1) == 1,
      isSosNode: (map['isSosNode'] as int? ?? 0) == 1,
      isShelterNode: (map['isShelterNode'] as int? ?? 0) == 1,
      isRescueNode: (map['isRescueNode'] as int? ?? 0) == 1,
      connectionState: PeerConnectionState.values.firstWhere(
        (e) => e.name == map['connectionState'],
        orElse: () => PeerConnectionState.connected,
      ),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  String get signalStrengthDescription {
    if (rssi == null) return 'Hop Count: $hopCount';
    if (rssi! >= -60) return 'Excellent (-${rssi!.abs()} dBm)';
    if (rssi! >= -75) return 'Good (-${rssi!.abs()} dBm)';
    if (rssi! >= -90) return 'Fair (-${rssi!.abs()} dBm)';
    return 'Weak (-${rssi!.abs()} dBm)';
  }
}
