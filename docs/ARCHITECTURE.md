# MeshConnect Architecture

## 1. System Architecture Overview

MeshConnect decouples platform-specific radio mechanics from the transport-agnostic protocol, routing, and cryptographic layers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER PRESENTATION LAYER                      │
│   Splash  •  Onboarding  •  Home  •  Chat  •  Map Canvas  •  SOS       │
│               Settings  •  Diagnostics  •  Simulation Mode            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                    APPLICATION & SERVICE COORDINATION                  │
│    DiscoveryService  •  BatteryService  •  PermissionService  •  SOS   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       MESH ENGINE & PROTOCOL CORE                      │
│  ┌───────────────────────┐  ┌──────────────────────┐  ┌─────────────┐  │
│  │    Routing Engine     │  │ Store-and-Forward    │  │ Crypto Core │  │
│  │   (Multi-Metric)      │  │ (SQLite MessageRepo) │  │  AES + Ed   │  │
│  └───────────────────────┘  └──────────────────────┘  └─────────────┘  │
│  ┌───────────────────────┐  ┌──────────────────────┐  ┌─────────────┐  │
│  │ Deduplication Cache   │  │ TTL & Hop Manager    │  │ Ack Manager │  │
│  └───────────────────────┘  └──────────────────────┘  └─────────────┘  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                    CROSS-PLATFORM TRANSPORT INTERFACE                  │
│                        (MeshTransport Abstraction)                     │
│               ├── NativeMeshTransport (Method / Event Channels)        │
│               └── DemoMeshTransport (Multi-Node Simulation Sandbox)    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
             ┌──────────────────────┴──────────────────────┐
             ▼                                             ▼
┌─────────────────────────┐                   ┌─────────────────────────┐
│  ANDROID KOTLIN LAYER   │                   │     IOS SWIFT LAYER     │
│  BleTransport (GATT)    │                   │  MultipeerTransport     │
│  WifiPeerTransport      │                   │  BluetoothTransport     │
│  PermissionManager      │                   │  PermissionManager      │
│  BatteryManager         │                   │  Keychain Storage       │
└─────────────────────────┘                   └─────────────────────────┘
```

---

## 2. Dynamic Routing Engine & Scoring Algorithm

Rather than relying on naive flooding or rigid static routes, MeshConnect uses a dynamic multi-metric scoring function:

$$\text{RouteScore} = (\text{LinkQuality} \times W_c) + \text{DestRelevance} - \text{HopPenalty} - \text{StalePenalty} - \text{BatteryPenalty}$$

### Metric Weights:
- **Connectivity Weight ($W_c = 30$)**: Proportional to link RSSI and packet success rate.
- **Destination Relevance ($W_d = 50$)**: Highest ($50$) if destination is direct neighbor; scales down inversely with hop count.
- **Hop Penalty**: Subtracts $10$ points per intermediate hop to favor shorter paths.
- **Stale Penalty**: Subtracts $0.5$ points per second since the last route beacon.
- **Battery Penalty**: Subtracts up to $20$ points if the relaying peer has depleted battery reserves.

---

## 3. Self-Healing Mesh Mechanism

If an intermediate relay disappears:
1. `TransportConnectionEvent(peerId, connected: false)` fires.
2. `RoutingEngine.invalidateNextHop(peerId)` purges all routes depending on the dead node.
3. Outbound packets in transit are returned to the `MessageForwarder` queue.
4. The router queries alternate candidates among connected peers (e.g. Medic Patrol instead of Volunteer).
5. Packets are dispatched along the newly discovered path without dropped frames.

---

## 4. Local SQLite Persistence Schema

Four tables back the offline store:
- `messages`: Message ID, protocol version, timestamps, encrypted payload, TTL, hop count, status, relay trail.
- `peers`: Mesh ID, display name, public key, last seen, RSSI, hop count, capabilities, role flags.
- `routes`: Source, destination, next hop, score, freshness, link quality.
- `sos_events`: SOS ID, origin peer, coordinates, status, relay history, acknowledgements.
