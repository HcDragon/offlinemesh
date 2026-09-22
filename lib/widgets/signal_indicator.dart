import 'package:flutter/material.dart';

class SignalIndicator extends StatelessWidget {
  final int? rssi;
  final int hopCount;

  const SignalIndicator({
    super.key,
    this.rssi,
    this.hopCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    int activeBars;
    Color barColor;

    if (rssi != null) {
      if (rssi! >= -65) {
        activeBars = 4;
        barColor = const Color(0xFF10B981);
      } else if (rssi! >= -78) {
        activeBars = 3;
        barColor = const Color(0xFF3B82F6);
      } else if (rssi! >= -90) {
        activeBars = 2;
        barColor = const Color(0xFFF59E0B);
      } else {
        activeBars = 1;
        barColor = const Color(0xFFEF4444);
      }
    } else {
      // Hops-based representation
      if (hopCount <= 1) {
        activeBars = 4;
        barColor = const Color(0xFF10B981);
      } else if (hopCount == 2) {
        activeBars = 3;
        barColor = const Color(0xFF3B82F6);
      } else if (hopCount == 3) {
        activeBars = 2;
        barColor = const Color(0xFFF59E0B);
      } else {
        activeBars = 1;
        barColor = const Color(0xFF94A3B8);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final height = 6.0 + (index * 3.5);
        final isActive = index < activeBars;
        return Container(
          width: 3.5,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          decoration: BoxDecoration(
            color: isActive ? barColor : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}
