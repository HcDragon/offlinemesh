# iOS Setup & Multipeer Connectivity Guide

## 1. Prerequisites
- macOS with Xcode 15+
- Physical iPhone or iPad with iOS 15+ for actual radio peer-to-peer transmission.
  *(iOS Simulator does not support Bluetooth peripheral mode or Multipeer Wi-Fi Direct)*.

---

## 2. Info.plist Permissions Configured

In `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>MeshConnect uses Bluetooth Low Energy to discover and communicate with nearby mesh peers without cellular or internet access.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>MeshConnect advertises your offline mesh node to relay and receive emergency messages from nearby peers.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>MeshConnect uses local peer-to-peer networking to route messages and SOS alerts across nearby devices.</string>

<key>NSBonjourServices</key>
<array>
    <string>_meshconnect._tcp</string>
    <string>_meshconnect._udp</string>
</array>

<key>NSLocationWhenInUseUsageDescription</key>
<string>MeshConnect captures your GPS coordinates only when you explicitly share your location or broadcast an Emergency SOS alert.</string>
```

---

## 3. Native Implementation Details

- **`MultipeerTransport.swift`**:
  - Uses Apple's `MultipeerConnectivity` framework (`MCSession`, `MCNearbyServiceAdvertiser`, `MCNearbyServiceBrowser`).
  - Automatically handles local Wi-Fi and Bluetooth radio links between Apple devices without external routers.
- **`BluetoothTransport.swift`**:
  - Exposes CoreBluetooth central and peripheral capability detection to Flutter.
- **`PermissionManager.swift`**:
  - Inspects `CBCentralManager` and `CLLocationManager` authorization status.

---

## 4. Building & Running on iOS

```bash
# Install CocoaPods
cd ios && pod install && cd ..

# Run on physical connected iPhone
flutter run -d <iphone-device-id>

# Open in Xcode for signing & profile configuration
open ios/Runner.xcworkspace
```
