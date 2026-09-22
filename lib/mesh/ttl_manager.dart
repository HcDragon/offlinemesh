import '../core/constants/app_constants.dart';
import '../core/errors/mesh_exception.dart';
import '../models/mesh_message.dart';

class TtlManager {
  /// Validates initial TTL on message creation based on priority
  int getInitialTtl(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return AppConstants.sosTtl;
      case MessagePriority.high:
        return 10;
      case MessagePriority.normal:
        return AppConstants.defaultTtl;
    }
  }

  /// Processes packet for relay: decrements TTL, increments hop count.
  /// Throws TtlExpiredException if packet has expired.
  MeshMessage processRelayTtl(MeshMessage message, String localNodeId) {
    if (message.ttl <= 1) {
      throw TtlExpiredException(message.messageId);
    }

    if (message.hopCount >= AppConstants.maxTtl) {
      throw TtlExpiredException(message.messageId);
    }

    final updatedRelays = List<String>.from(message.relayHops);
    if (!updatedRelays.contains(localNodeId)) {
      updatedRelays.add(localNodeId);
    }

    return message.copyWith(
      ttl: message.ttl - 1,
      hopCount: message.hopCount + 1,
      relayHops: updatedRelays,
    );
  }

  bool isExpired(MeshMessage message) {
    return message.ttl <= 0 || message.hopCount >= AppConstants.maxTtl;
  }
}
