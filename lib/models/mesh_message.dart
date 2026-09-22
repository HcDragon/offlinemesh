import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'message_status.dart';

enum MessageType {
  text,
  location,
  sos,
  ack,
  hello,
  keyExchange,
  routeUpdate,
  deliveryReceipt;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() ||
             e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => MessageType.text,
    );
  }
}

enum MessagePriority {
  normal,
  high,
  emergency;

  static MessagePriority fromString(String value) {
    return MessagePriority.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MessagePriority.normal,
    );
  }
}

class MeshMessage {
  final int protocolVersion;
  final MessageType messageType;
  final String messageId;
  final String senderId;
  final String destinationId;
  final int createdAt;
  final int ttl;
  final int hopCount;
  final MessagePriority priority;
  final String payload; // Base64 ciphertext or structured JSON payload
  final String signature;
  final String nonce;
  final MessageStatus status;
  final List<String> relayHops;

  const MeshMessage({
    this.protocolVersion = 1,
    required this.messageType,
    required this.messageId,
    required this.senderId,
    required this.destinationId,
    required this.createdAt,
    this.ttl = 7,
    this.hopCount = 0,
    this.priority = MessagePriority.normal,
    required this.payload,
    this.signature = '',
    required this.nonce,
    this.status = MessageStatus.queued,
    this.relayHops = const [],
  });

  bool get isBroadcast => destinationId == '*' || destinationId == 'broadcast';
  bool get isSos => messageType == MessageType.sos || priority == MessagePriority.emergency;

  MeshMessage copyWith({
    int? protocolVersion,
    MessageType? messageType,
    String? messageId,
    String? senderId,
    String? destinationId,
    int? createdAt,
    int? ttl,
    int? hopCount,
    MessagePriority? priority,
    String? payload,
    String? signature,
    String? nonce,
    MessageStatus? status,
    List<String>? relayHops,
  }) {
    return MeshMessage(
      protocolVersion: protocolVersion ?? this.protocolVersion,
      messageType: messageType ?? this.messageType,
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      destinationId: destinationId ?? this.destinationId,
      createdAt: createdAt ?? this.createdAt,
      ttl: ttl ?? this.ttl,
      hopCount: hopCount ?? this.hopCount,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      signature: signature ?? this.signature,
      nonce: nonce ?? this.nonce,
      status: status ?? this.status,
      relayHops: relayHops ?? this.relayHops,
    );
  }

  /// Wire format map for serialization across Bluetooth / P2P transport
  Map<String, dynamic> toWireMap() {
    return {
      'v': protocolVersion,
      'type': messageType.name,
      'id': messageId,
      'src': senderId,
      'dst': destinationId,
      'ts': createdAt,
      'ttl': ttl,
      'hops': hopCount,
      'prio': priority.name,
      'data': payload,
      'sig': signature,
      'nonce': nonce,
      'relays': relayHops,
    };
  }

  factory MeshMessage.fromWireMap(Map<String, dynamic> map) {
    return MeshMessage(
      protocolVersion: map['v'] as int? ?? 1,
      messageType: MessageType.fromString(map['type'] as String? ?? 'text'),
      messageId: map['id'] as String,
      senderId: map['src'] as String,
      destinationId: map['dst'] as String? ?? '*',
      createdAt: map['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ttl: map['ttl'] as int? ?? 7,
      hopCount: map['hops'] as int? ?? 0,
      priority: MessagePriority.fromString(map['prio'] as String? ?? 'normal'),
      payload: map['data'] as String? ?? '',
      signature: map['sig'] as String? ?? '',
      nonce: map['nonce'] as String? ?? const Uuid().v4(),
      status: MessageStatus.relayed,
      relayHops: (map['relays'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  /// DB record map
  Map<String, dynamic> toDbMap() {
    return {
      'messageId': messageId,
      'protocolVersion': protocolVersion,
      'messageType': messageType.name,
      'senderId': senderId,
      'destinationId': destinationId,
      'createdAt': createdAt,
      'ttl': ttl,
      'hopCount': hopCount,
      'priority': priority.name,
      'payload': payload,
      'signature': signature,
      'nonce': nonce,
      'status': status.name,
      'relayHops': jsonEncode(relayHops),
    };
  }

  factory MeshMessage.fromDbMap(Map<String, dynamic> map) {
    List<String> hops = [];
    if (map['relayHops'] != null) {
      try {
        hops = (jsonDecode(map['relayHops'] as String) as List<dynamic>).map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return MeshMessage(
      protocolVersion: map['protocolVersion'] as int? ?? 1,
      messageType: MessageType.fromString(map['messageType'] as String? ?? 'text'),
      messageId: map['messageId'] as String,
      senderId: map['senderId'] as String,
      destinationId: map['destinationId'] as String,
      createdAt: map['createdAt'] as int,
      ttl: map['ttl'] as int? ?? 7,
      hopCount: map['hopCount'] as int? ?? 0,
      priority: MessagePriority.fromString(map['priority'] as String? ?? 'normal'),
      payload: map['payload'] as String? ?? '',
      signature: map['signature'] as String? ?? '',
      nonce: map['nonce'] as String? ?? '',
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.delivered,
      ),
      relayHops: hops,
    );
  }

  String serialize() => jsonEncode(toWireMap());

  factory MeshMessage.deserialize(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return MeshMessage.fromWireMap(map);
  }
}
