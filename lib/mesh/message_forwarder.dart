import 'dart:async';
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../core/logging/mesh_logger.dart';
import '../models/message_status.dart';
import '../storage/message_repository.dart';
import 'peer_manager.dart';
import 'routing_engine.dart';

typedef SendPayloadCallback = Future<bool> Function(String nextHopId, List<int> payloadBytes);
typedef BroadcastCallback = Future<bool> Function(List<int> payloadBytes);

class MessageForwarder {
  final MessageRepository _messageRepository;
  final RoutingEngine routingEngine;
  final PeerManager peerManager;
  Timer? _retryTimer;
  bool _isProcessingQueue = false;

  SendPayloadCallback? onSendPayload;
  BroadcastCallback? onBroadcast;

  MessageForwarder({
    MessageRepository? messageRepository,
    required this.routingEngine,
    required this.peerManager,
  }) : _messageRepository = messageRepository ?? MessageRepository() {
    _startQueueWorker();
  }

  void _startQueueWorker() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(
      const Duration(seconds: AppConstants.retryIntervalSeconds),
      (_) => processStoreAndForwardQueue(),
    );
  }

  Future<void> processStoreAndForwardQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      final pending = await _messageRepository.getPendingQueuedMessages();
      if (pending.isEmpty) return;

      final connectedPeers = peerManager.connectedPeers;
      if (connectedPeers.isEmpty) return;

      for (final msg in pending) {
        if (msg.isBroadcast) {
          final bytes = utf8.encode(msg.serialize());
          if (onBroadcast != null) {
            final sent = await onBroadcast!(bytes);
            if (sent) {
              await _messageRepository.updateMessageStatus(msg.messageId, MessageStatus.relayed);
            }
          }
          continue;
        }

        final bestRoute = routingEngine.findBestNextHop(msg.destinationId, connectedPeers);
        if (bestRoute != null && onSendPayload != null) {
          final bytes = utf8.encode(msg.serialize());
          final sent = await onSendPayload!(bestRoute.nextHopId, bytes);
          if (sent) {
            await _messageRepository.updateMessageStatus(msg.messageId, MessageStatus.relaying);
            MeshLogger().log(
              MeshLogType.messageForwarded,
              'MessageForwarder',
              'Store-and-forward: Message ${msg.messageId} forwarded via nextHop ${bestRoute.nextHopId}',
            );
          }
        }
      }
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'MessageForwarder', 'Error processing store-and-forward queue: $e');
    } finally {
      _isProcessingQueue = false;
    }
  }

  void triggerImmediateFlush() {
    processStoreAndForwardQueue();
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
