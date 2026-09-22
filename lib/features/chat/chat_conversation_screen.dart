import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../models/mesh_message.dart';
import '../../models/peer.dart';
import '../../widgets/message_bubble.dart';
import 'message_detail_screen.dart';

class ChatConversationScreen extends StatefulWidget {
  final Peer targetPeer;

  const ChatConversationScreen({super.key, required this.targetPeer});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final meshEngine = context.read<MeshEngine>();
      await meshEngine.sendChatMessage(
        destinationId: widget.targetPeer.meshId,
        text: text,
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _shareLocation() async {
    final meshEngine = context.read<MeshEngine>();
    // Send simulated or current coordinates
    const lat = 37.7749;
    const lng = -122.4194;
    final locText = '📍 Shared Location: $lat, $lng';
    await meshEngine.sendChatMessage(
      destinationId: widget.targetPeer.meshId,
      text: locText,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFDBEAFE),
              child: Text(
                widget.targetPeer.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.targetPeer.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF10B981)),
                    ],
                  ),
                  Text(
                    '${widget.targetPeer.meshId} • ${widget.targetPeer.hopCount} hop${widget.targetPeer.hopCount == 1 ? "" : "s"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_location_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Share Coordinates',
            onPressed: _shareLocation,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // E2E Encryption Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFFF1F5F9),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    'End-to-End Encrypted via AES-256-GCM & Ed25519',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Message List
            Expanded(
              child: FutureBuilder<List<MeshMessage>>(
                future: meshEngine.messageRepository.getConversation(widget.targetPeer.meshId),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 12),
                          Text(
                            'No messages yet',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Packets are relayed securely across mesh hops.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == meshEngine.localPeerId;
                      return MessageBubble(
                        message: msg,
                        isMe: isMe,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MessageDetailScreen(message: msg)),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type encrypted message...',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF2563EB),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
