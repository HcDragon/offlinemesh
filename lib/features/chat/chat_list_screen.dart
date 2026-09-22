import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../models/mesh_message.dart';
import '../../models/peer.dart';
import '../../widgets/status_badge.dart';
import 'chat_conversation_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();
    final peers = meshEngine.peerManager.allPeers;
    final isDemo = meshEngine.transportManager.isDemoMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: StatusBadge(
              type: isDemo ? BadgeType.demoMode : BadgeType.offline,
              customLabel: isDemo ? 'SIMULATION' : 'OFFLINE',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Broadcast Channel Item
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatConversationScreen(
                    targetPeer: Peer(
                      meshId: '*',
                      displayName: 'Global Mesh Broadcast',
                      lastSeen: DateTime.now(),
                      hopCount: 1,
                    ),
                  ),
                ),
              );
            },
            leading: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(Icons.campaign_rounded, color: Color(0xFF1E40AF), size: 26),
            ),
            title: const Text(
              'Global Mesh Broadcast',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            subtitle: const Text(
              'Multi-hop broadcast to all nearby nodes in radio range',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ),
          const Divider(indent: 72, endIndent: 20),

          // Discovered Peers Conversations
          if (peers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),
                    const Text(
                      'No peers currently reachable',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nearby devices running MeshConnect will automatically appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    if (!isDemo)
                      ElevatedButton.icon(
                        onPressed: () => meshEngine.switchMode(true),
                        icon: const Icon(Icons.science, size: 16),
                        label: const Text('Try Simulation Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            ...peers.map((peer) {
              return FutureBuilder<List<MeshMessage>>(
                future: meshEngine.messageRepository.getConversation(peer.meshId),
                builder: (context, snapshot) {
                  final msgs = snapshot.data ?? [];
                  final lastMsg = msgs.isNotEmpty ? msgs.last : null;

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(targetPeer: peer),
                        ),
                      );
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Icon(
                            peer.isRescueNode
                                ? Icons.local_hospital_rounded
                                : (peer.isShelterNode ? Icons.roofing_rounded : Icons.smartphone_rounded),
                            color: const Color(0xFF475569),
                            size: 22,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: peer.connectionState == PeerConnectionState.connected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          peer.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${peer.hopCount} hop${peer.hopCount == 1 ? "" : "s"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      lastMsg?.payload ?? 'Tap to begin encrypted peer chat',
                      style: TextStyle(
                        fontSize: 13,
                        color: lastMsg != null ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                        fontWeight: lastMsg != null ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  );
                },
              );
            }),
        ],
      ),
    );
  }
}
