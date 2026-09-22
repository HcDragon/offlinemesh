import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../models/peer.dart';
import '../../widgets/node_card.dart';
import '../../widgets/status_badge.dart';
import '../chat/chat_conversation_screen.dart';

class PeersScreen extends StatelessWidget {
  const PeersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();
    final peers = meshEngine.peerManager.allPeers;
    final isDemo = meshEngine.transportManager.isDemoMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nearby Devices', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Rescan Radios',
            onPressed: () {
              meshEngine.transportManager.activeTransport.startDiscovery();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning for nearby mesh nodes...'), duration: Duration(seconds: 2)),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: StatusBadge(
              type: isDemo ? BadgeType.demoMode : BadgeType.connected,
              customLabel: isDemo ? 'SIMULATION' : 'SCANNING',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDemo
                        ? 'Simulation Mode: Showing simulated rescue nodes and multi-hop relays.'
                        : 'Actual radio peer discovery via Bluetooth Low Energy and Local Network. Signal strength reflects physical proximity.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          if (peers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.radar_rounded, size: 56, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 16),
                    const Text(
                      'No mesh peers in radio range',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bring another phone with MeshConnect nearby to establish a connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => meshEngine.switchMode(true),
                      icon: const Icon(Icons.science, size: 18),
                      label: const Text('Launch Simulation Mode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...peers.map((peer) {
              return NodeCard(
                peer: peer,
                onTap: () => _openChat(context, peer),
                onChatPressed: () => _openChat(context, peer),
              );
            }),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, Peer peer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(targetPeer: peer),
      ),
    );
  }
}
