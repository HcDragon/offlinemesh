import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/logging/mesh_logger.dart';

class PermissionService extends ChangeNotifier {
  bool _bluetoothGranted = false;
  bool _locationGranted = false;
  bool _nearbyDevicesGranted = false;

  bool get isMeshReady => _bluetoothGranted && _nearbyDevicesGranted;
  bool get bluetoothGranted => _bluetoothGranted;
  bool get locationGranted => _locationGranted;
  bool get nearbyDevicesGranted => _nearbyDevicesGranted;

  Future<void> checkPermissions() async {
    final btStatus = await Permission.bluetooth.status;
    final scanStatus = await Permission.bluetoothScan.status;
    final advStatus = await Permission.bluetoothAdvertise.status;
    final connStatus = await Permission.bluetoothConnect.status;
    final locStatus = await Permission.locationWhenInUse.status;
    final nearbyStatus = await Permission.nearbyWifiDevices.status;

    _bluetoothGranted = btStatus.isGranted || connStatus.isGranted;
    _nearbyDevicesGranted = scanStatus.isGranted || advStatus.isGranted || nearbyStatus.isGranted || btStatus.isGranted;
    _locationGranted = locStatus.isGranted;

    notifyListeners();
  }

  Future<bool> requestMeshPermissions() async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ].request();

      _bluetoothGranted = statuses[Permission.bluetooth]?.isGranted == true ||
                           statuses[Permission.bluetoothConnect]?.isGranted == true;
      _nearbyDevicesGranted = statuses[Permission.bluetoothScan]?.isGranted == true ||
                              statuses[Permission.bluetoothAdvertise]?.isGranted == true ||
                              statuses[Permission.bluetooth]?.isGranted == true;

      MeshLogger().log(
        MeshLogType.discovery,
        'PermissionService',
        'Requested Bluetooth & Nearby permissions: bt=$_bluetoothGranted, nearby=$_nearbyDevicesGranted',
      );

      notifyListeners();
      return isMeshReady;
    } catch (e) {
      MeshLogger().log(MeshLogType.error, 'PermissionService', 'Error requesting permissions: $e');
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      _locationGranted = status.isGranted;
      notifyListeners();
      return _locationGranted;
    } catch (_) {
      return false;
    }
  }
}
