import 'package:flutter/material.dart';
import '../models/peer.dart';
import 'signal_indicator.dart';

class NodeCard extends StatelessWidget {
  final Peer peer;
  final VoidCallback? onTap;
  final VoidCallback? onChatPressed;

  const NodeCard({
    super.key,
    required this.peer,
    this.onTap,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = peer.connectionState == PeerConnectionState.connected;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: isConnected ? 1.5 : 1.0,
        ),
      ),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Avatar with status ring
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _getNodeColor(peer).withValues(alpha: 0.15),
                    child: Icon(
                      _getNodeIcon(peer),
                      color: _getNodeColor(peer),
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
                        color: isConnected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Peer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            peer.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (peer.isRescueNode) ...[
                          const SizedBox(width: 6),
                          _buildRoleTag('RESCUE', const Color(0xFFDC2626)),
                        ] else if (peer.isShelterNode) ...[
                          const SizedBox(width: 6),
                          _buildRoleTag('SHELTER', const Color(0xFF2563EB)),
                        ] else if (peer.isRelay) ...[
                          const SizedBox(width: 6),
                          _buildRoleTag('RELAY', const Color(0xFF059669)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${peer.meshId} • ${peer.hopCount == 1 ? "Direct Link" : "${peer.hopCount} Hops"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      peer.estimatedDistanceMeters != null
                          ? 'Est. Distance: ${peer.estimatedDistanceMeters!.toStringAsFixed(1)} m'
                          : peer.signalStrengthDescription,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Signal & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SignalIndicator(rssi: peer.rssi, hopCount: peer.hopCount),
                  const SizedBox(height: 8),
                  if (onChatPressed != null)
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                      onPressed: onChatPressed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getNodeColor(Peer p) {
    if (p.isSosNode) return const Color(0xFFDC2626);
    if (p.isRescueNode) return const Color(0xFF7C3AED);
    if (p.isShelterNode) return const Color(0xFF2563EB);
    return const Color(0xFF059669);
  }

  IconData _getNodeIcon(Peer p) {
    if (p.isSosNode) return Icons.warning_rounded;
    if (p.isRescueNode) return Icons.local_hospital_rounded;
    if (p.isShelterNode) return Icons.roofing_rounded;
    return Icons.smartphone_rounded;
  }
}
