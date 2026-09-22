# Android Setup & Hardware Radio Guide

## 1. Prerequisites
- Android Studio / Android SDK (API 34+)
- Physical Android device with Bluetooth Low Energy (BLE) peripheral mode support.
  *(Note: Android Emulators do not support physical BLE advertising or GATT peripheral hosting)*.

---

## 2. Permissions Configured

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="false" />
<uses-feature android:name="android.hardware.wifi.direct" android:required="false" />
```

---

## 3. Native Implementation Details

- **`BleTransport.kt`**:
  - Implements `BluetoothLeAdvertiser` broadcasting `MESH_SERVICE_UUID` (`0000FE60-0000-1000-8000-00805F9B34FB`).
  - Implements `BluetoothLeScanner` with low-latency scan settings to discover nearby mesh advertisements.
  - Implements `BluetoothGattServer` hosting RX and TX characteristics for peer-to-peer frame delivery.
- **`PermissionManager.kt`**: Runtime checks for Android 12+ (API 31+) nearby device permissions.
- **`BatteryManager.kt`**: Detects battery level and power save mode to adjust scanning duty cycles.

---

## 4. Building & Running on Android

```bash
# Get dependencies
flutter pub get

# Run on physical connected Android device
flutter run -d <device-id>

# Build release APK
flutter build apk --release
```
