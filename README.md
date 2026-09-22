# MESHCONNECT

> **Decentralized, Offline-First, Multi-Hop Peer-to-Peer Communication System Where Smartphones Become the Network.**

---

## 1. Project Objective

**MeshConnect** is a cross-platform mobile application (Flutter + Kotlin + Swift) that allows nearby smartphones to discover one another, build self-healing mesh topologies, and exchange encrypted text, GPS coordinates, and Emergency SOS alerts without depending on:

- Cellular network towers
- Mobile internet or mobile data
- Wi-Fi routers or hot-spots
- Cloud servers (No Firebase, Supabase, or AWS)
- Central databases
- External communication hardware

```text
PHONE A  ──(Hop 1)──►  PHONE B  ──(Hop 2)──►  PHONE C  ──(Hop 3)──►  RESCUE / DESTINATION
```

---

## 2. Key Features

- **Actual Radio Hardware Transport**:
  - **Android**: Native Kotlin Bluetooth Low Energy (BLE) peripheral advertiser, scanner, GATT client/server, and Wi-Fi Direct capability checks.
  - **iOS**: Native Swift Apple MultipeerConnectivity and CoreBluetooth adapter.
- **Unified Transport Abstraction**:
  - Shared Dart application domain communicating across abstract `MeshTransport` interface.
- **End-to-End Cryptography**:
  - AES-256-GCM authenticated payload encryption.
  - Ed25519 digital signatures for origin authenticity and tamper detection.
  - X25519 Diffie-Hellman (ECDH) key agreement.
  - Keystore & Keychain secure storage via `flutter_secure_storage`.
  - Replay protection with unique UUID nonces and sliding time windows.
- **Dynamic Multi-Metric Routing Engine**:
  - Scores routes based on connectivity quality, hop penalty, stale penalty, and peer battery levels.
- **Self-Healing Mesh**:
  - Automatically detects node drop-outs, purges broken routes, and recalculates alternative paths.
- **Store-and-Forward**:
  - Persistent SQLite database stores outgoing packets when destination is out of range and auto-relays when new peers connect.
- **Deduplication & TTL**:
  - Bounded LRU cache suppresses duplicate packets and packet loops.
  - Configurable TTL (7 hops default, 15 hops for SOS).
- **Emergency SOS System**:
  - High-priority preemption, GPS location attachment, multi-hop broadcast, and delivery confirmation timeline.
- **Interactive Mesh Topology Map**:
  - Custom canvas displaying local node, active relays, shelter nodes, rescue gateways, and signal connection paths.
- **Dedicated Multi-Node Simulator (Hackathon Demo Mode)**:
  - Clearly marked `SIMULATION / DEMO MODE` for presentations, demonstrating A → B → C → Rescue Gateway packet hops with interactive node-dropping.
- **Deep Packet Inspector**:
  - Inspect wire headers, TTL remaining, Ed25519 signature strings, and relay node audit trails.

---

## 3. Technology Stack

- **Frontend**: Flutter (Material 3), Dart 3
- **Android Native**: Kotlin, BluetoothLeScanner, BluetoothLeAdvertiser, BluetoothGattServer, Wi-Fi P2P
- **iOS Native**: Swift, MultipeerConnectivity, CoreBluetooth
- **State Management**: Provider
- **Storage**: SQLite (`sqflite`), Android Keystore, iOS Keychain
- **Cryptography**: `cryptography` (Pure Dart + accelerated platform engine for Ed25519, X25519, AES-256-GCM)

---

## 4. Project Structure

```text
lib/
  core/
    constants/       # Protocol version, timeouts, default TTLs, scoring weights
    errors/          # Domain exceptions (BluetoothDisabledException, etc.)
    logging/         # Structured logger with zero-plaintext redaction policy
  models/            # MeshMessage, Peer, MeshRoute, SosEvent, DeviceCapabilities
  crypto/            # CryptoService (AES-256-GCM, Ed25519, X25519), KeyManager
  mesh/              # RoutingEngine, DeduplicationManager, TtlManager, MessageForwarder, PeerManager, AckManager, MeshEngine
  transport/         # MeshTransport interface, NativeMeshTransport, DemoMeshTransport, TransportManager
  storage/           # MeshDatabase (SQLite), MessageRepository, PeerRepository, RouteRepository, SosRepository
  services/          # SosService, BatteryService, DiscoveryService, PermissionService
  features/
    splash/          # App initialization
    onboarding/      # Concept introduction & permission setup
    home/            # Dashboard, telemetry stats, recent messages
    chat/            # Encrypted conversation, packet inspector
    map/             # Interactive radar topology map canvas
    peers/           # Nearby devices list & signal telemetry
    sos/             # High-priority emergency trigger & live status
    settings/        # Identity, battery modes, radio capabilities
    diagnostics/     # Live telemetry metrics & raw log buffer
    demo/            # Multi-Node Simulation Sandbox
  widgets/           # EmergencySosButton, StatusBadge, SignalIndicator, NodeCard, MessageBubble
  main.dart

android/app/src/main/kotlin/com/meshconnect/meshconnect/
  MeshTransportPlugin.kt   # MethodChannel & EventChannel bridge
  BleTransport.kt          # Android BLE advertiser, scanner & GATT server
  WifiPeerTransport.kt     # Wi-Fi Direct capability layer
  PermissionManager.kt     # Android 12+ runtime permission checks
  BatteryManager.kt        # Android battery & power saving monitor

ios/Runner/
  MeshTransportPlugin.swift   # iOS FlutterPlugin bridge
  MultipeerTransport.swift    # Apple MultipeerConnectivity implementation
  BluetoothTransport.swift    # CoreBluetooth capability detection
  PermissionManager.swift     # iOS permission status helper
```

---

## 5. Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Verify Code & Run Tests
```bash
flutter analyze
flutter test
```
*(All 17 unit and integration tests execute and pass out of the box).*

### 3. Run on Physical Device
```bash
# Android
flutter run -d <android-device-id>

# iOS
flutter run -d <iphone-device-id>
```

---

## 6. Complete Documentation Index

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Mesh Protocol Specification](docs/MESH_PROTOCOL.md)
- [Security & Threat Model](docs/SECURITY.md)
- [Android Setup Guide](docs/ANDROID_SETUP.md)
- [iOS Setup Guide](docs/IOS_SETUP.md)
- [Testing & Telemetry Guide](docs/TESTING.md)
- [Hackathon Demo Presentation Script](docs/DEMO_GUIDE.md)
- [Troubleshooting & FAQ](docs/TROUBLESHOOTING.md)

---

## 7. Known Platform Limitations

1. **Simulators**: Neither the Android Emulator nor the iOS Simulator expose physical Bluetooth peripheral mode or Multipeer Wi-Fi Direct radios. Physical devices must be used to test over-the-air radio transmission.
2. **iOS Background Execution**: In prolonged iOS background suspension, Apple limits BLE advertising frequency. MeshConnect utilizes state preservation and opportunistic foreground synchronization.
3. **Cross-OS BLE GATT Compatibility**: Cross-OS BLE advertising between Android and iOS requires consistent 128-bit UUID filtering across both vendors.
