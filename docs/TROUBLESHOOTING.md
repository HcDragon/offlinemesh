# MeshConnect Troubleshooting Guide

## 1. Common Hardware & Radio Issues

### Bluetooth Turned Off
- **Symptom**: App indicates `Bluetooth adapter is powered off or unavailable`.
- **Cause**: Device Bluetooth toggle is switched off or airplane mode disabled the radio.
- **Fix**: Open OS Quick Settings or Settings and toggle Bluetooth ON.

### Permission Denied (Android 12+)
- **Symptom**: `Permission denied for BLUETOOTH_SCAN or BLUETOOTH_CONNECT`.
- **Cause**: Android 12 introduced granular `Nearby Devices` permissions.
- **Fix**: Open Android Settings → Apps → MeshConnect → Permissions → Enable **Nearby Devices**.

### Location Permission Not Granted
- **Symptom**: GPS coordinates unavailable during SOS broadcast.
- **Cause**: Location access is set to "Never".
- **Fix**: Open Settings → Apps → MeshConnect → Location → Select **"While using the app"**. Note: MeshConnect strictly requires location only when broadcasting SOS.

---

## 2. Platform Background Restrictions

### iOS Background Suspension
- **Behavior**: iOS may throttle background BLE advertising and Multipeer browsing if the app is suspended for prolonged periods.
- **Mitigation**: MeshConnect uses state preservation and foreground opportunistic polling. Keep MeshConnect in the foreground or active in the app switcher during rescue operations.

### Android Battery Optimization (Doze Mode)
- **Behavior**: Aggressive battery saver profiles (e.g. Xiaomi MIUI / Samsung OneUI) may sleep background GATT servers.
- **Fix**: Disable battery optimization for MeshConnect in Device Settings → Battery → Unrestricted.

---

## 3. Network & Routing Diagnostics

### Packets Remain in "Queued" State
- **Cause**: The destination node is currently out of direct radio range, and no connected relay peers are available.
- **Normal Behavior**: Store-and-forward will preserve the message in local SQLite until an intermediate peer comes within range.

### Message Dropped with TTL Expired
- **Cause**: The packet traversed more than 7 hops (or 15 for SOS) without reaching the destination.
- **Mitigation**: High-priority SOS packets use extended TTLs. In large mesh deployments, configure `AppConstants.defaultTtl` higher in settings.
