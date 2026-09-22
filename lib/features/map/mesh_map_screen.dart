import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mesh/mesh_engine.dart';
import '../../models/peer.dart';
import '../../widgets/status_badge.dart';

class MeshMapScreen extends StatefulWidget {
  const MeshMapScreen({super.key});

  @override
  State<MeshMapScreen> createState() => _MeshMapScreenState();
}

class _MeshMapScreenState extends State<MeshMapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();
    final peers = meshEngine.peerManager.allPeers;
    final isDemo = meshEngine.transportManager.isDemoMode;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark radar/tactical background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mesh Topology Map',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Offline Real-Time Node Connections',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: StatusBadge(
              type: isDemo ? BadgeType.demoMode : BadgeType.offline,
              customLabel: isDemo ? 'SIMULATION' : 'OFFLINE',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Topological Canvas
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(300),
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: SizedBox(
                width: 700,
                height: 700,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: TopologyMapPainter(
                        localPeerId: meshEngine.localPeerId,
                        peers: peers,
                        pulseValue: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Map Legend Overlay at Bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('You (Local)', const Color(0xFF38BDF8)),
                  _buildLegendItem('Connected', const Color(0xFF10B981)),
                  _buildLegendItem('Shelter', const Color(0xFF3B82F6)),
                  _buildLegendItem('Rescue', const Color(0xFFA855F7)),
                  _buildLegendItem('SOS Alert', const Color(0xFFEF4444)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TopologyMapPainter extends CustomPainter {
  final String localPeerId;
  final List<Peer> peers;
  final double pulseValue;

  TopologyMapPainter({
    required this.localPeerId,
    required this.peers,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw radar concentric rings
    final ringPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int r = 80; r <= 320; r += 70) {
      canvas.drawCircle(center, r.toDouble(), ringPaint);
    }

    // 2. Animated pulse ring from local node
    final pulsePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: (1.0 - pulseValue) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 40.0 + (pulseValue * 220.0), pulsePaint);

    // 3. Layout peers radially based on hop count and index
    final Map<String, Offset> nodePositions = {
      localPeerId: center,
    };

    final hop1Peers = peers.where((p) => p.hopCount <= 1).toList();
    final hop2Peers = peers.where((p) => p.hopCount == 2).toList();
    final hop3Peers = peers.where((p) => p.hopCount >= 3).toList();

    _layoutTier(center, hop1Peers, 130.0, nodePositions, 0.0);
    _layoutTier(center, hop2Peers, 220.0, nodePositions, math.pi / 4);
    _layoutTier(center, hop3Peers, 290.0, nodePositions, math.pi / 6);

    // 4. Draw connection mesh links
    final linkPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final multiHopPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final peer in peers) {
      final pos = nodePositions[peer.meshId];
      if (pos == null) continue;

      if (peer.hopCount <= 1) {
        // Direct link to local
        canvas.drawLine(center, pos, linkPaint);
      } else {
        // Link to nearest intermediate hop
        final parent = hop1Peers.isNotEmpty ? nodePositions[hop1Peers.first.meshId] : center;
        if (parent != null) {
          canvas.drawLine(parent, pos, multiHopPaint);
        }
      }
    }

    // 5. Draw peer nodes
    for (final peer in peers) {
      final pos = nodePositions[peer.meshId];
      if (pos == null) continue;
      _drawNode(canvas, pos, peer.displayName, _getNodeColor(peer), false);
    }

    // 6. Draw central local node
    _drawNode(canvas, center, 'You (Node)', const Color(0xFF38BDF8), true);
  }

  void _layoutTier(
    Offset center,
    List<Peer> tierPeers,
    double radius,
    Map<String, Offset> positions,
    double angleOffset,
  ) {
    if (tierPeers.isEmpty) return;
    final step = (2 * math.pi) / tierPeers.length;
    for (int i = 0; i < tierPeers.length; i++) {
      final angle = angleOffset + (i * step);
      final x = center.dx + (radius * math.cos(angle));
      final y = center.dy + (radius * math.sin(angle));
      positions[tierPeers[i].meshId] = Offset(x, y);
    }
  }

  void _drawNode(Canvas canvas, Offset offset, String label, Color color, bool isLocal) {
    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, isLocal ? 20 : 16, glowPaint);

    // Node body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, isLocal ? 11 : 8, bodyPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(offset, isLocal ? 11 : 8, borderPaint);

    // Text Label
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(offset.dx - (tp.width / 2), offset.dy + 14));
  }

  Color _getNodeColor(Peer p) {
    if (p.isSosNode) return const Color(0xFFEF4444);
    if (p.isRescueNode) return const Color(0xFFA855F7);
    if (p.isShelterNode) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  @override
  bool shouldRepaint(covariant TopologyMapPainter oldDelegate) => true;
}
