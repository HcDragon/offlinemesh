class DeviceCapabilities {
  final bool bleSupported;
  final bool bluetoothEnabled;
  final bool advertisingSupported;
  final bool wifiDirectSupported;
  final bool locationPermissionGranted;
  final bool nearbyDevicesPermissionGranted;
  final int batteryLevel;
  final bool powerSaveMode;
  final String platform;

  const DeviceCapabilities({
    this.bleSupported = false,
    this.bluetoothEnabled = false,
    this.advertisingSupported = false,
    this.wifiDirectSupported = false,
    this.locationPermissionGranted = false,
    this.nearbyDevicesPermissionGranted = false,
    this.batteryLevel = 100,
    this.powerSaveMode = false,
    this.platform = 'unknown',
  });

  factory DeviceCapabilities.fromMap(Map<dynamic, dynamic> map) {
    return DeviceCapabilities(
      bleSupported: map['bleSupported'] as bool? ?? false,
      bluetoothEnabled: map['bluetoothEnabled'] as bool? ?? false,
      advertisingSupported: map['advertisingSupported'] as bool? ?? false,
      wifiDirectSupported: map['wifiDirectSupported'] as bool? ?? false,
      locationPermissionGranted: map['locationGranted'] as bool? ?? false,
      nearbyDevicesPermissionGranted: map['nearbyDevicesGranted'] as bool? ?? false,
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? 100,
      powerSaveMode: map['powerSaveMode'] as bool? ?? false,
      platform: map['platform'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bleSupported': bleSupported,
      'bluetoothEnabled': bluetoothEnabled,
      'advertisingSupported': advertisingSupported,
      'wifiDirectSupported': wifiDirectSupported,
      'locationPermissionGranted': locationPermissionGranted,
      'nearbyDevicesPermissionGranted': nearbyDevicesPermissionGranted,
      'batteryLevel': batteryLevel,
      'powerSaveMode': powerSaveMode,
      'platform': platform,
    };
  }

  bool get isReadyForMesh => bluetoothEnabled && nearbyDevicesPermissionGranted;
}
