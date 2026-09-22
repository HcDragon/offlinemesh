enum MessageStatus {
  queued,
  relaying,
  relayed,
  delivered,
  ackReceived,
  failed;

  String get displayName {
    switch (this) {
      case MessageStatus.queued:
        return 'Queued Offline';
      case MessageStatus.relaying:
        return 'Relaying...';
      case MessageStatus.relayed:
        return 'Relayed via Mesh';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.ackReceived:
        return 'ACK Confirmed';
      case MessageStatus.failed:
        return 'Delivery Failed';
    }
  }
}
