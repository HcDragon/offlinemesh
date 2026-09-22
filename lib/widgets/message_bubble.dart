import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mesh_message.dart';
import '../models/message_status.dart';

class MessageBubble extends StatelessWidget {
  final MeshMessage message;
  final bool isMe;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    final isSos = message.isSos;

    Color bubbleBg;
    Color textColor;
    if (isSos) {
      bubbleBg = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
    } else if (isMe) {
      bubbleBg = const Color(0xFF1E40AF);
      textColor = Colors.white;
    } else {
      bubbleBg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF0F172A);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: isSos ? Border.all(color: const Color(0xFFDC2626), width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (isSos) ...[
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text(
                      'EMERGENCY SOS ALERT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message.payload,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hop badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${message.hopCount} hop${message.hopCount == 1 ? "" : "s"}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white60 : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.queued:
        return const Icon(Icons.schedule_rounded, size: 13, color: Colors.white60);
      case MessageStatus.relaying:
        return const Icon(Icons.swap_horiz_rounded, size: 13, color: Colors.white70);
      case MessageStatus.relayed:
        return const Icon(Icons.check, size: 13, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 13, color: Colors.white);
      case MessageStatus.ackReceived:
        return const Icon(Icons.verified, size: 13, color: Color(0xFF67E8F9));
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 13, color: Color(0xFFFCA5A5));
    }
  }
}
