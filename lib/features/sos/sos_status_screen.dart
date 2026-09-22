import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../models/sos_event.dart';
import '../../services/sos_service.dart';
import '../../widgets/status_badge.dart';

class SosStatusScreen extends StatelessWidget {
  final String sosId;

  const SosStatusScreen({super.key, required this.sosId});

  @override
  Widget build(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();
    final sosService = context.watch<SosService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Emergency Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: StatusBadge(type: BadgeType.sos),
          ),
        ],
      ),
      body: FutureBuilder<SosEvent?>(
        future: meshEngine.sosRepository.getSosEventById(sosId),
        builder: (context, snapshot) {
          final event = snapshot.data ?? sosService.currentActiveSos;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Pulse icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDC2626), width: 2),
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      size: 48,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'SOS BROADCAST ACTIVE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Broadcasting continuous encrypted emergency packets across all reachable mesh frequencies.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
                  ),
                  const SizedBox(height: 32),

                  // Hop Progression Timeline
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      children: [
                        _buildTimelineStep(
                          title: 'SOS CREATED & SIGNED',
                          subtitle: 'Ed25519 signature attached with GPS payload',
                          isComplete: true,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'PEERS REACHED',
                          subtitle: '${meshEngine.peerManager.connectedPeers.length} direct radio links active',
                          isComplete: meshEngine.peerManager.connectedPeers.isNotEmpty,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'RELAYED ACROSS MESH',
                          subtitle: event != null && event.relayHistory.isNotEmpty
                              ? 'Forwarded via ${event.relayHistory.length} intermediate hops'
                              : 'Propagating to next-hop nodes...',
                          isComplete: event != null && event.relayHistory.length > 1,
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'RESCUE NODE RECEIVED',
                          subtitle: event != null && event.status == SosStatus.acknowledged
                              ? 'Rescue Gateway HQ confirmed receipt ✓'
                              : 'Awaiting end-to-end acknowledgement',
                          isComplete: event != null && event.status == SosStatus.acknowledged,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Resolve Emergency Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await sosService.resolveEmergency(sosId);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Emergency alert marked as resolved.')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF475569)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Resolve / Cancel Alert', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isComplete,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete ? const Color(0xFF10B981) : const Color(0xFF334155),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isComplete
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isComplete ? const Color(0xFF10B981) : const Color(0xFF334155),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isComplete ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
