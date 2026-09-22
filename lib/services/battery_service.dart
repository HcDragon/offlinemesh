import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/mesh_logger.dart';

enum BatteryOperatingMode {
  normal,
  batterySaver,
  critical;

  String get displayName {
    switch (this) {
      case BatteryOperatingMode.normal:
        return 'Normal Mesh Mode';
      case BatteryOperatingMode.batterySaver:
        return 'Battery Saver Mode';
      case BatteryOperatingMode.critical:
        return 'Critical Power Mode';
    }
  }

  String get description {
    switch (this) {
      case BatteryOperatingMode.normal:
        return 'Full discovery and continuous multi-hop packet relaying.';
      case BatteryOperatingMode.batterySaver:
        return 'Reduced scanning frequency to conserve energy while maintaining mesh connectivity.';
      case BatteryOperatingMode.critical:
        return 'Ultra-low duty cycle. Prioritizes Emergency SOS and direct messages only.';
    }
  }
}

class BatteryService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.meshconnect/transport');

  int _batteryLevel = 100;
  BatteryOperatingMode _operatingMode = BatteryOperatingMode.normal;
  Timer? _pollingTimer;

  int get batteryLevel => _batteryLevel;
  BatteryOperatingMode get operatingMode => _operatingMode;

  Future<void> initialize() async {
    await _fetchBatteryLevel();

    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _fetchBatteryLevel();
    });
  }

  Future<void> _fetchBatteryLevel() async {
    try {
      final info = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryInfo');
      if (info != null && info.containsKey('batteryLevel')) {
        final lvl = (info['batteryLevel'] as num).toInt();
        if (lvl >= 0) {
          _batteryLevel = lvl;
        }
      }
      _updateOperatingMode();
    } catch (_) {
      _batteryLevel = 100;
    }
  }

  void _updateOperatingMode() {
    final oldMode = _operatingMode;
    if (_batteryLevel <= AppConstants.criticalBatteryThresholdPercent) {
      _operatingMode = BatteryOperatingMode.critical;
    } else if (_batteryLevel <= AppConstants.batterySaverThresholdPercent) {
      _operatingMode = BatteryOperatingMode.batterySaver;
    } else {
      _operatingMode = BatteryOperatingMode.normal;
    }

    if (oldMode != _operatingMode) {
      MeshLogger().log(
        MeshLogType.batteryModeChanged,
        'BatteryService',
        'Operating mode changed: ${_operatingMode.displayName} (Battery: $_batteryLevel%)',
      );
      notifyListeners();
    }
  }

  void setManualMode(BatteryOperatingMode mode) {
    _operatingMode = mode;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
