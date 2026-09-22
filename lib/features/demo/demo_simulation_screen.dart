import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../widgets/status_badge.dart';

class DemoSimulationScreen extends StatefulWidget {
  const DemoSimulationScreen({super.key});

  @override
  State<DemoSimulationScreen> createState() => _DemoSimulationScreenState();
}

class _DemoSimulationScreenState extends State<DemoSimulationScreen> {
  int _activeHopStep = 0;
  bool _isAutoSimulating = false;
  String _simulationLog = 'Ready to simulate packet relay.';

  @override
  void initState() {
    super.initState();
    _ensureDemoModeEnabled();
  }

  Future<void> _ensureDemoModeEnabled() async {
    final engine = context.read<MeshEngine>();
    if (!engine.transportManager.isDemoMode) {
      await engine.switchMode(true);
    }
  }

  void _runMultiHopSimulation({bool isSos = false}) async {
    if (_isAutoSimulating) return;
    setState(() {
      _isAutoSimulating = true;
      _activeHopStep = 1;
      _simulationLog = 'Origin: [Node A (You)] encrypted & dispatched packet.';
    });

    final engine = context.read<MeshEngine>();

    if (isSos) {
      await engine.broadcastSos(emergencyNote: 'SIMULATION: Multi-hop rescue needed!');
    } else {
      await engine.sendChatMessage(
        destinationId: 'node-rescue-gw',
        text: 'Need emergency medical supplies at Sector 4.',
      );
    }

    // Step 2: Volunteer
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _activeHopStep = 2;
      _simulationLog = '[HOP 1] Volunteer 02 verified signature & forwarded to Shelter Node Alpha.';
    });

    // Step 3: Shelter
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _activeHopStep = 3;
      _simulationLog = '[HOP 2] Shelter Node Alpha decremented TTL (6 remaining) & relayed to Rescue Gateway.';
    });

    // Step 4: Rescue Gateway
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _activeHopStep = 4;
      _simulationLog = '[HOP 3] Rescue Gateway HQ DELIVERED packet and returned end-to-end ACK ✓';
      _isAutoSimulating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<MeshEngine>();
    final demoTransport = engine.transportManager.demoTransport;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Multi-Node Simulator', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: StatusBadge(type: BadgeType.demoMode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_rounded, color: Color(0xFFD97706), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIMULATION / DEMO MODE',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF92400E)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Demonstrates deterministic multi-hop propagation without needing 4 physical phones during presentations.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Simulation Chain Visualization
          const Text(
            'Multi-Hop Path (A → B → C → Rescue)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),

          _buildNodeRow(
            stepNumber: 1,
            title: 'Node A: User Phone (Local)',
            subtitle: 'Generates Ed25519 signature & AES-256 ciphertext',
            isActive: _activeHopStep >= 1,
            isCurrent: _activeHopStep == 1,
            icon: Icons.phone_android_rounded,
            color: const Color(0xFF2563EB),
          ),
          _buildArrowDown(_activeHopStep >= 2),

          _buildNodeRow(
            stepNumber: 2,
            title: 'Node B: Volunteer 02',
            subtitle: 'Direct BLE hop (RSSI: -64 dBm). Relays packet',
            isActive: _activeHopStep >= 2,
            isCurrent: _activeHopStep == 2,
            icon: Icons.person_pin_circle_rounded,
            color: const Color(0xFF059669),
            onToggle: (online) {
              demoTransport?.toggleNodeStatus('node-vol-02', online);
              setState(() {});
            },
            isOnline: demoTransport?.simulatedNodes['node-vol-02']?.isOnline ?? true,
          ),
          _buildArrowDown(_activeHopStep >= 3),

          _buildNodeRow(
            stepNumber: 3,
            title: 'Node C: Shelter Node Alpha',
            subtitle: 'Multi-hop relay node (2 hops from local)',
            isActive: _activeHopStep >= 3,
            isCurrent: _activeHopStep == 3,
            icon: Icons.roofing_rounded,
            color: const Color(0xFF0284C7),
            onToggle: (online) {
              demoTransport?.toggleNodeStatus('node-shelter-01', online);
              setState(() {});
            },
            isOnline: demoTransport?.simulatedNodes['node-shelter-01']?.isOnline ?? true,
          ),
          _buildArrowDown(_activeHopStep >= 4),

          _buildNodeRow(
            stepNumber: 4,
            title: 'Node D: Rescue Gateway HQ',
            subtitle: 'Final destination. Decrypts & dispatches ACK packet',
            isActive: _activeHopStep >= 4,
            isCurrent: _activeHopStep == 4,
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 24),

          // Simulation Status Terminal
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _simulationLog,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAutoSimulating ? null : () => _runMultiHopSimulation(isSos: false),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Simulate Message Hop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAutoSimulating ? null : () => _runMultiHopSimulation(isSos: true),
                  icon: const Icon(Icons.emergency_rounded),
                  label: const Text('Simulate SOS Hop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Switch back to Native Radio mode button
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await engine.switchMode(false);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Switched back to Native Physical Radio mode.')),
                  );
                }
              },
              icon: const Icon(Icons.sensors_rounded, size: 16),
              label: const Text('Exit Demo & Return to Native BLE Radios'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeRow({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCurrent,
    required IconData icon,
    required Color color,
    void Function(bool)? onToggle,
    bool isOnline = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? color : (isActive ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isOnline ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    decoration: isOnline ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (onToggle != null) ...[
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(fontSize: 11, color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.w700),
            ),
            Switch.adaptive(
              value: isOnline,
              activeTrackColor: const Color(0xFF10B981),
              onChanged: onToggle,
            ),
          ] else if (isActive)
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
        ],
      ),
    );
  }

  Widget _buildArrowDown(bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Center(
        child: Icon(
          Icons.arrow_downward_rounded,
          size: 20,
          color: active ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
