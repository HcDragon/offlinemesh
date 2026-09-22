import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/permission_service.dart';
import '../home/home_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permService = context.watch<PermissionService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Device Permissions',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enable Mesh Radios',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'MeshConnect communicates purely device-to-device. We require local radio access to discover nearby phones without cloud servers.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              _buildPermissionTile(
                title: 'Bluetooth & Nearby Devices',
                subtitle: 'Required for discovery and exchange of encrypted packets.',
                icon: Icons.bluetooth_searching_rounded,
                isGranted: permService.nearbyDevicesGranted || permService.bluetoothGranted,
                onTap: () => permService.requestMeshPermissions(),
              ),
              const SizedBox(height: 16),

              _buildPermissionTile(
                title: 'Location Services',
                subtitle: 'Used solely when broadcasting an Emergency SOS or sharing coordinates.',
                icon: Icons.location_on_outlined,
                isGranted: permService.locationGranted,
                onTap: () => permService.requestLocationPermission(),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Enter MeshConnect',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isGranted ? const Color(0xFF10B981) : const Color(0xFF64748B),
            foregroundColor: Colors.white,
            radius: 20,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle, color: Color(0xFF10B981))
          else
            TextButton(
              onPressed: onTap,
              child: const Text('Allow'),
            ),
        ],
      ),
    );
  }
}
