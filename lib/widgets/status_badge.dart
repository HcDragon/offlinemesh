import 'package:flutter/material.dart';

enum BadgeType {
  offline,
  connected,
  demoMode,
  sos,
  warning,
}

class StatusBadge extends StatelessWidget {
  final BadgeType type;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.type,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (type) {
      case BadgeType.offline:
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF334155);
        icon = Icons.cloud_off_rounded;
        label = customLabel ?? 'Offline Mesh Mode';
        break;
      case BadgeType.connected:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon = Icons.sensors_rounded;
        label = customLabel ?? 'Mesh Active';
        break;
      case BadgeType.demoMode:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        icon = Icons.science_rounded;
        label = customLabel ?? 'SIMULATION / DEMO MODE';
        break;
      case BadgeType.sos:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        icon = Icons.warning_amber_rounded;
        label = customLabel ?? 'SOS BROADCAST ACTIVE';
        break;
      case BadgeType.warning:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        icon = Icons.error_outline_rounded;
        label = customLabel ?? 'Attention Required';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
