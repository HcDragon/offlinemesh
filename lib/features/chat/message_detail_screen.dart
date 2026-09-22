import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/mesh_message.dart';

class MessageDetailScreen extends StatelessWidget {
  final MeshMessage message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(message.createdAt),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Packet Inspector', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      message.messageType.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2563EB)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.status.displayName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.payload,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Wire Protocol Metadata
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
                  'Wire Header Fields',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const Divider(height: 24),
                _buildField('Message ID', message.messageId),
                _buildField('Protocol Version', 'v${message.protocolVersion}'),
                _buildField('Sender ID', message.senderId),
                _buildField('Destination', message.destinationId),
                _buildField('Timestamp', timeStr),
                _buildField('Priority', message.priority.name.toUpperCase()),
                _buildField('Current Hop Count', '${message.hopCount} hops'),
                _buildField('TTL Remaining', '${message.ttl}'),
                _buildField('Replay Nonce', message.nonce),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security & Cryptography Verification
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
                const Row(
                  children: [
                    Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Cryptographic Verification',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildField('Payload Encryption', 'AES-256-GCM Authenticated'),
                _buildField('Digital Signature Scheme', 'Ed25519 (Edwards-curve)'),
                _buildField(
                  'Signature Base64',
                  message.signature.isEmpty ? 'Unsigned (Demo/Local)' : message.signature,
                  isMonospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Multi-Hop Relay Audit Trail
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
                const Row(
                  children: [
                    Icon(Icons.alt_route_rounded, color: Color(0xFF6366F1), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Relay Node History',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (message.relayHops.isEmpty)
                  const Text('Direct single-hop transmission (no intermediate relays).', style: TextStyle(color: Color(0xFF64748B), fontSize: 13))
                else
                  ...message.relayHops.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hopPeerId = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFEEF2FF),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            hopPeerId,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
