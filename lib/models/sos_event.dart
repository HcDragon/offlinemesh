import 'dart:convert';

enum SosStatus {
  active,
  relayed,
  acknowledged,
  resolved;

  String get displayName {
    switch (this) {
      case SosStatus.active:
        return 'SOS Active';
      case SosStatus.relayed:
        return 'Relayed by Mesh';
      case SosStatus.acknowledged:
        return 'Rescue Node ACK';
      case SosStatus.resolved:
        return 'Resolved';
    }
  }
}

class SosEvent {
  final String sosId;
  final String originPeerId;
  final String originDisplayName;
  final DateTime timestamp;
  final SosStatus status;
  final double? latitude;
  final double? longitude;
  final String emergencyNote;
  final List<String> relayHistory;
  final int acknowledgedAt;

  const SosEvent({
    required this.sosId,
    required this.originPeerId,
    required this.originDisplayName,
    required this.timestamp,
    this.status = SosStatus.active,
    this.latitude,
    this.longitude,
    this.emergencyNote = 'EMERGENCY: Immediate assistance required!',
    this.relayHistory = const [],
    this.acknowledgedAt = 0,
  });

  SosEvent copyWith({
    String? sosId,
    String? originPeerId,
    String? originDisplayName,
    DateTime? timestamp,
    SosStatus? status,
    double? latitude,
    double? longitude,
    String? emergencyNote,
    List<String>? relayHistory,
    int? acknowledgedAt,
  }) {
    return SosEvent(
      sosId: sosId ?? this.sosId,
      originPeerId: originPeerId ?? this.originPeerId,
      originDisplayName: originDisplayName ?? this.originDisplayName,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      emergencyNote: emergencyNote ?? this.emergencyNote,
      relayHistory: relayHistory ?? this.relayHistory,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'sosId': sosId,
      'originPeerId': originPeerId,
      'originDisplayName': originDisplayName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'emergencyNote': emergencyNote,
      'relayHistory': jsonEncode(relayHistory),
      'acknowledgedAt': acknowledgedAt,
    };
  }

  factory SosEvent.fromDbMap(Map<String, dynamic> map) {
    List<String> relays = [];
    if (map['relayHistory'] != null) {
      try {
        relays = (jsonDecode(map['relayHistory'] as String) as List<dynamic>).map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return SosEvent(
      sosId: map['sosId'] as String,
      originPeerId: map['originPeerId'] as String,
      originDisplayName: map['originDisplayName'] as String? ?? 'Peer',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: SosStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SosStatus.active,
      ),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      emergencyNote: map['emergencyNote'] as String? ?? '',
      relayHistory: relays,
      acknowledgedAt: map['acknowledgedAt'] as int? ?? 0,
    );
  }
}
