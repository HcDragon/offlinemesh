# MeshConnect Protocol Specification (v1)

## 1. Overview
The **MeshConnect Protocol (MCP)** is a lightweight, decentralized, offline-first wire protocol designed for opportunistic peer-to-peer and multi-hop mesh networking over Bluetooth Low Energy (BLE), Wi-Fi Direct, and Apple MultipeerConnectivity.

---

## 2. Wire Packet Format

Each packet transmitted over radio frame transports is serialized as a compact UTF-8 JSON object (or binary-encoded frame) containing the following fields:

```json
{
  "v": 1,
  "type": "text",
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "src": "node-7b89f012",
  "dst": "node-rescue-gw",
  "ts": 1774300000000,
  "ttl": 7,
  "hops": 0,
  "prio": "normal",
  "data": "{\"cipher\":\"...\",\"nonce\":\"...\",\"mac\":\"...\"}",
  "sig": "MEUCIQD...Base64Signature...",
  "nonce": "e3b0c442-98fc-1c14-9afb-f4c8996fb924",
  "relays": ["node-7b89f012"]
}
```

### Header Fields

| Field | Type | Description |
|---|---|---|
| `v` | Integer | Protocol major version (currently `1`). |
| `type` | String | Message category enum (`text`, `location`, `sos`, `ack`, `hello`, `keyExchange`, `routeUpdate`, `deliveryReceipt`). |
| `id` | String | Universally unique message identifier (UUID v4). |
| `src` | String | Mesh Node ID of the original sender. |
| `dst` | String | Destination Mesh Node ID, or `*` for mesh-wide broadcast. |
| `ts` | Integer | Creation Unix timestamp in milliseconds. |
| `ttl` | Integer | Time-To-Live counter. Decremented by 1 at each hop. Packet dropped if `<= 1`. |
| `hops` | Integer | Total hops traversed. Incremented by 1 at each relay. |
| `prio` | String | Priority class (`normal`, `high`, `emergency`). |
| `data` | String | Payload. For text and SOS, this is AES-256-GCM ciphertext JSON. |
| `sig` | String | Ed25519 digital signature of headers + ciphertext. |
| `nonce` | String | Random cryptographic nonce for replay attack prevention. |
| `relays` | Array[String]| Ordered array of node IDs that forwarded this frame. |

---

## 3. Message Types

1. `TEXT`: End-to-end encrypted private message or local broadcast note.
2. `LOCATION`: Encrypted GPS coordinates (`latitude`, `longitude`, `accuracy`).
3. `SOS`: High-priority emergency broadcast (`priority: emergency`, `ttl: 15`). Bypasses queues.
4. `ACK`: End-to-end delivery confirmation containing `ackMessageId` and destination confirmation.
5. `HELLO`: Periodic beacon announcing node availability, public keys, and hop distance.
6. `KEY_EXCHANGE`: Exchange of X25519 public keys to derive session keys via ECDH.
7. `ROUTE_UPDATE`: Telemetry sharing neighbor link qualities and next-hop costs.
8. `DELIVERY_RECEIPT`: Intermediate relay hop confirmation.

---

## 4. Deduplication & Loop Suppression

Mesh networks with redundant paths are vulnerable to broadcast storms. Every node maintains a **DeduplicationManager** with a bounded LRU cache (default 2,000 entries):

```
On Packet Arrival:
1. Lookup messageId in _seenMessageIds.
2. If found:
     LOG: Duplicate packet suppressed.
     DROP packet immediately.
3. If new:
     Add messageId to _seenMessageIds.
     Process packet further.
```

---

## 5. TTL & Hop Count Rules

- **Initial TTL Assignment**:
  - `normal` priority: Default 7 hops.
  - `high` priority: 10 hops.
  - `emergency` (SOS): 15 hops.
- **Relay Processing**:
  - Decrement `ttl = ttl - 1`.
  - Increment `hopCount = hopCount + 1`.
  - Append local node ID to `relays`.
  - If `ttl <= 0` or `hopCount >= 16`: drop packet and log `TtlExpiredException`.

---

## 6. Store-and-Forward State Machine

```text
       [Message Created]
               │
               ▼
        [Route Available?]
          ├── YES ──► [Relaying via Next Hop] ──► [Delivered] ──► [ACK Received]
          └── NO  ──► [Queued in Local SQLite]
                            │
               (Peer Discovered / Link Restored)
                            │
                            ▼
                     [Forward Queue]
```

When no immediate next-hop is active for `dst`, the message is persisted locally in SQLite with `status = 'queued'`. Background workers re-attempt delivery every 10 seconds whenever new peers appear.
