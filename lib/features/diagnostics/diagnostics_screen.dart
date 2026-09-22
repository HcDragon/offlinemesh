import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/logging/mesh_logger.dart';
import '../../mesh/mesh_engine.dart';
import '../../services/battery_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  String _filterTag = 'ALL';

  @override
  Widget build(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();
    final batteryService = context.watch<BatteryService>();
    final logger = MeshLogger();
    final allLogs = logger.logs;

    final filteredLogs = _filterTag == 'ALL'
        ? allLogs
        : allLogs.where((l) => l.tag.toUpperCase() == _filterTag.toUpperCase() || l.type.name.toUpperCase() == _filterTag.toUpperCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mesh Diagnostics', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Copy Diagnostic Report',
            onPressed: () {
              final report = allLogs.map((l) => l.toString()).join('\n');
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagnostics telemetry copied to clipboard.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Telemetry Grid
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'Connected Peers',
                  '${meshEngine.peerManager.connectedPeers.length}',
                  'of ${meshEngine.peerManager.allPeers.length} discovered',
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<int>(
                  future: meshEngine.messageRepository.getDeliveredCount(),
                  builder: (context, snap) {
                    return _buildStatBox(
                      'Delivered',
                      '${snap.data ?? 0}',
                      'Confirmed ACK',
                      const Color(0xFF2563EB),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<int>(
                  future: meshEngine.messageRepository.getRelayedCount(),
                  builder: (context, snap) {
                    return _buildStatBox(
                      'Relayed Hops',
                      '${snap.data ?? 0}',
                      'Multi-hop frames',
                      const Color(0xFF8B5CF6),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Routing Engine Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Routing & Battery State',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const Divider(height: 20),
                _buildRow('Active Routing Destinations', '${meshEngine.routingEngine.routes.length} targets'),
                _buildRow('Battery Operating Profile', batteryService.operatingMode.name.toUpperCase()),
                _buildRow('Battery Reserve Level', '${batteryService.batteryLevel}%'),
                _buildRow('Transport Mode', meshEngine.transportManager.isDemoMode ? 'SIMULATION / DEMO MODE' : 'NATIVE HARDWARE RADIO'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Structured Event Logs Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Telemetry Log Buffer',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              Text(
                '${filteredLogs.length} events',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'MeshEngine', 'DemoTransport', 'NativeTransport', 'RoutingEngine', 'AckManager'].map((tag) {
                final isSelected = _filterTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (sel) {
                      setState(() => _filterTag = tag);
                    },
                    selectedColor: const Color(0xFFDBEAFE),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Log entries terminal card
          Container(
            height: 350,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: filteredLogs.isEmpty
                ? const Center(
                    child: Text('No telemetry logs matching filter.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  )
                : ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[filteredLogs.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '[${log.type.name.toUpperCase()}]',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _getLogColor(log.type),
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${log.tag}: ${log.message}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE2E8F0),
                                  fontFamily: 'monospace',
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Color _getLogColor(MeshLogType type) {
    switch (type) {
      case MeshLogType.error:
        return const Color(0xFFEF4444);
      case MeshLogType.sosCreated:
      case MeshLogType.sosRelayed:
        return const Color(0xFFF87171);
      case MeshLogType.messageDelivered:
      case MeshLogType.ackReceived:
        return const Color(0xFF34D399);
      case MeshLogType.messageForwarded:
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
