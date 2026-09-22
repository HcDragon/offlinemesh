import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../crypto/key_manager.dart';
import '../../mesh/mesh_engine.dart';
import '../../models/device_capabilities.dart';
import '../../services/battery_service.dart';
import '../demo/demo_simulation_screen.dart';
import '../diagnostics/diagnostics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshEngine = context.watch<MeshEngine>();
    final batteryService = context.watch<BatteryService>();
    final keyManager = KeyManager();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings & Identity', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Node Identity Card
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
                    Icon(Icons.fingerprint_rounded, color: Color(0xFF2563EB), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Decentralized Mesh Identity',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('Display Name', keyManager.displayName),
                _buildInfoRow('Mesh Node ID', keyManager.meshId),
                _buildInfoRow(
                  'Ed25519 Public Key',
                  keyManager.signingPublicKeyBase64.isNotEmpty
                      ? '${keyManager.signingPublicKeyBase64.substring(0, 16)}...'
                      : 'Ephemeral Demo Key',
                  isMonospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Battery Operating Mode
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
                    const Row(
                      children: [
                        Icon(Icons.battery_charging_full_rounded, color: Color(0xFF10B981), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Battery Profile',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Text(
                      '${batteryService.batteryLevel}%',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                DropdownButtonFormField<BatteryOperatingMode>(
                  initialValue: batteryService.operatingMode,
                  decoration: InputDecoration(
                    labelText: 'Operating Mode',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: BatteryOperatingMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.displayName),
                    );
                  }).toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      batteryService.setManualMode(mode);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  batteryService.operatingMode.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Platform Capabilities & Radios
          FutureBuilder<DeviceCapabilities>(
            future: meshEngine.transportManager.activeTransport.getCapabilities(),
            builder: (context, snapshot) {
              final caps = snapshot.data ?? const DeviceCapabilities();
              return Container(
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
                        Icon(Icons.cell_tower_rounded, color: Color(0xFF6366F1), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Hardware Radio Status',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildCapabilityRow('Platform Driver', caps.platform.toUpperCase()),
                    _buildCapabilityRow('Bluetooth Low Energy', caps.bleSupported ? 'Supported' : 'Unavailable', isOk: caps.bleSupported),
                    _buildCapabilityRow('Bluetooth Radio Enabled', caps.bluetoothEnabled ? 'Active' : 'Disabled', isOk: caps.bluetoothEnabled),
                    _buildCapabilityRow('BLE Peripheral Advertising', caps.advertisingSupported ? 'Supported' : 'Limited', isOk: caps.advertisingSupported),
                    _buildCapabilityRow('Wi-Fi Peer-to-Peer / Direct', caps.wifiDirectSupported ? 'Supported' : 'Unavailable', isOk: caps.wifiDirectSupported),
                    _buildCapabilityRow('Nearby Devices Permission', caps.nearbyDevicesPermissionGranted ? 'Granted' : 'Denied', isOk: caps.nearbyDevicesPermissionGranted),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Developer & Demonstration Tools
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
                  'Diagnostics & Hackathon Presentation',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.analytics_rounded, color: Color(0xFF2563EB)),
                  title: const Text('Live Network Diagnostics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Packet telemetry, dropped frames, raw logs', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.science_rounded, color: Color(0xFFD97706)),
                  title: const Text('Multi-Node Simulation Sandbox', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Interactive A → B → C → Rescue packet hops', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DemoSimulationScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Database purge
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await meshEngine.messageRepository.getAllMessages();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local SQLite database reset.')),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
              label: const Text('Clear Local Database Cache', style: TextStyle(color: Color(0xFFDC2626))),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(String label, String value, {bool isOk = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isOk ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOk ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
