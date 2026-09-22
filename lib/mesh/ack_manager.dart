import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/logging/mesh_logger.dart';
import '../models/mesh_message.dart';
import '../models/message_status.dart';
import '../storage/message_repository.dart';

class AckManager {
  final MessageRepository _messageRepository;
  final Map<String, Completer<bool>> _pendingAcks = {};

  AckManager([MessageRepository? messageRepository])
      : _messageRepository = messageRepository ?? MessageRepository();

  /// Create an ACK message to send back to the original sender
  MeshMessage createAckMessage({
    required MeshMessage originalMessage,
    required String localPeerId,
  }) {
    final ackPayload = jsonEncode({
      'ackMessageId': originalMessage.messageId,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
      'totalHops': originalMessage.hopCount,
      'status': 'DELIVERED',
    });

    return MeshMessage(
      protocolVersion: 1,
      messageType: MessageType.ack,
      messageId: const Uuid().v4(),
      senderId: localPeerId,
      destinationId: originalMessage.senderId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      ttl: 7,
      priority: MessagePriority.high,
      payload: ackPayload,
      nonce: const Uuid().v4(),
    );
  }

  /// Process an incoming ACK packet
  Future<void> handleIncomingAck(MeshMessage ackMessage) async {
    try {
      final map = jsonDecode(ackMessage.payload) as Map<String, dynamic>;
      final targetMessageId = map['ackMessageId'] as String?;

      if (targetMessageId != null) {
        await _messageRepository.updateMessageStatus(
          targetMessageId,
          MessageStatus.ackReceived,
        );

        final completer = _pendingAcks.remove(targetMessageId);
        completer?.complete(true);

        MeshLogger().log(
          MeshLogType.ackReceived,
          'AckManager',
          'ACK confirmed for message $targetMessageId from ${ackMessage.senderId} (Hops: ${ackMessage.hopCount})',
        );
      }
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'AckManager', 'Error handling ACK packet: $e');
    }
  }

  void registerPendingMessage(String messageId, {Duration timeout = const Duration(seconds: 30)}) {
    final completer = Completer<bool>();
    _pendingAcks[messageId] = completer;

    Timer(timeout, () {
      if (_pendingAcks.containsKey(messageId)) {
        _pendingAcks.remove(messageId);
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    });
  }
}
