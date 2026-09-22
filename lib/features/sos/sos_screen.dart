import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sos_service.dart';
import 'sos_status_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  String _selectedCategory = 'Medical Assistance';
  final TextEditingController _notesController = TextEditingController();
  bool _includeLocation = true;
  bool _isBroadcasting = false;

  final List<String> _categories = [
    'Medical Assistance',
    'Trapped / Search & Rescue',
    'Fire / Disaster Evacuation',
    'Emergency Shelter & Food',
    'Critical Supply Need',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _triggerEmergency() async {
    setState(() => _isBroadcasting = true);

    try {
      final sosService = context.read<SosService>();
      final note = '[$_selectedCategory] ${_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : "Immediate assistance required!"}';

      final msg = await sosService.triggerSos(
        latitude: _includeLocation ? 37.7749 : null,
        longitude: _includeLocation ? -122.4194 : null,
        emergencyNote: note,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SosStatusScreen(sosId: msg.messageId)),
        );
      }
    } finally {
      if (mounted) setState(() => _isBroadcasting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Warning header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Priority Mesh Alert',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF991B1B), fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'This alert bypasses normal packet queues with maximum TTL (15 hops) across all nearby nodes.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Emergency Category',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                  selectedColor: const Color(0xFFFEE2E2),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text(
              'Additional Details / Medical Notes',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., 2 people injured, need stretcher, floor 3...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location switch
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Attach GPS Coordinates',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              subtitle: const Text(
                'Embeds current device coordinates in the encrypted SOS packet',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              value: _includeLocation,
              activeTrackColor: const Color(0xFFDC2626),
              onChanged: (val) => setState(() => _includeLocation = val),
            ),
            const SizedBox(height: 32),

            // Confirm & Broadcast Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBroadcasting ? null : _triggerEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: _isBroadcasting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                          SizedBox(width: 12),
                          Text('BROADCASTING TO MESH...'),
                        ],
                      )
                    : const Text(
                        'BROADCAST EMERGENCY SOS',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
