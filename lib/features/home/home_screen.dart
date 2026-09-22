import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../models/mesh_message.dart';
import '../../models/peer.dart';
import '../../services/battery_service.dart';
import '../../widgets/emergency_sos_button.dart';
import '../../widgets/node_card.dart';
import '../../widgets/status_badge.dart';
import '../chat/chat_conversation_screen.dart';
import '../chat/chat_list_screen.dart';
import '../demo/demo_simulation_screen.dart';
import '../diagnostics/diagnostics_screen.dart';
import '../map/mesh_map_screen.dart';
import '../peers/peers_screen.dart';
import '../settings/settings_screen.dart';
import '../sos/sos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeDashboard(context),
      const MeshMapScreen(),
      const ChatListScreen(),
      const PeersScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedNavIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (i) => setState(() => _selectedNavIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2563EB)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF2563EB)),
            label: 'Mesh Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB)),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors, color: Color(0xFF2563EB)),
            label: 'Peers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF2563EB)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();
    final batteryService = context.watch<BatteryService>();
    final isDemoMode = meshEngine.transportManager.isDemoMode;

    final connectedPeers = meshEngine.peerManager.connectedPeers;
    final totalPeers = meshEngine.peerManager.allPeers;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // App Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MESHCONNECT',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Node ID: ${meshEngine.localPeerId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.analytics_outlined, color: Color(0xFF475569)),
                      tooltip: 'Diagnostics',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isDemoMode ? Icons.science : Icons.science_outlined,
                        color: isDemoMode ? const Color(0xFFD97706) : const Color(0xFF64748B),
                      ),
                      tooltip: 'Simulation Demo Mode',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DemoSimulationScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Banner (Offline Mode + Demo indicator)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const StatusBadge(type: BadgeType.offline),
                const SizedBox(width: 8),
                if (isDemoMode)
                  const StatusBadge(type: BadgeType.demoMode)
                else
                  const StatusBadge(type: BadgeType.connected),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Emergency SOS Prominent Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: EmergencySosButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SosScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Mesh Telemetry Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Nearby Nodes',
                    value: '${totalPeers.length}',
                    subtitle: 'In Radio Range',
                    icon: Icons.cell_tower_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Connected',
                    value: '${connectedPeers.length}',
                    subtitle: 'Active Relays',
                    icon: Icons.hub_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Battery',
                    value: '${batteryService.batteryLevel}%',
                    subtitle: batteryService.operatingMode.name.toUpperCase(),
                    icon: Icons.battery_charging_full_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedNavIndex = 2); // Switch to Messages
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedNavIndex = 1); // Switch to Map
                    },
                    icon: const Icon(Icons.share_location_rounded, size: 18),
                    label: const Text('Share Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nearby Peers Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Nodes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedNavIndex = 3); // Switch to Peers
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),

          if (totalPeers.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.radar_rounded, size: 40, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'Scanning for mesh nodes...',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ensure Bluetooth is turned on. Nodes within BLE range will connect automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else
            ...totalPeers.take(3).map(
              (peer) => NodeCard(
                peer: peer,
                onTap: () => _openChatWithPeer(context, peer),
                onChatPressed: () => _openChatWithPeer(context, peer),
              ),
            ),

          const SizedBox(height: 24),

          // Recent Broadcasts / Messages
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedNavIndex = 2);
                  },
                  child: const Text('All Messages'),
                ),
              ],
            ),
          ),

          FutureBuilder<List<MeshMessage>>(
            future: meshEngine.messageRepository.getAllMessages(),
            builder: (context, snapshot) {
              final msgs = snapshot.data ?? [];
              if (msgs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No mesh messages yet. Broadcast an emergency or select a peer to begin chatting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
                );
              }

              return Column(
                children: msgs.take(3).map((m) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: m.isSos ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                      child: Icon(
                        m.isSos ? Icons.warning_amber_rounded : Icons.chat_bubble_outline_rounded,
                        color: m.isSos ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      m.isSos ? '🚨 EMERGENCY SOS' : (m.destinationId == '*' ? 'Mesh Broadcast' : 'To: ${m.destinationId}'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      m.payload,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: Text(
                      '${m.hopCount} hop${m.hopCount == 1 ? "" : "s"}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  void _openChatWithPeer(BuildContext context, Peer peer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(targetPeer: peer),
      ),
    );
  }
}
