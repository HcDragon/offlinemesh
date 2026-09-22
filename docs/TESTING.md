# MeshConnect Testing & Telemetry Guide

## 1. Automated Test Suite

MeshConnect contains automated tests covering the protocol, cryptography, deduplication, TTL expiration, scoring algorithm, and multi-hop simulation:

```bash
flutter test
```

### Test Coverage Summary:
- `test/protocol_test.dart`: Serialization, deserialization, priority rules, wire format, DB mapping.
- `test/crypto_test.dart`: Ed25519 digital signatures, signature verification, tamper rejection, AES-256-GCM authenticated encryption/decryption, X25519 ECDH key agreement.
- `test/deduplication_and_ttl_test.dart`: Duplicate packet suppression, bounded cache eviction, TTL decrement per relay, max hop limits, TTL expired exceptions.
- `test/routing_engine_test.dart`: Scoring function calculation, link quality weighting, stale/battery penalty, self-healing path selection.
- `test/multi_hop_integration_test.dart`: End-to-end multi-hop simulation (Node A → Node B → Node C → Rescue Gateway) with delivery acknowledgement.

---

## 2. Real-Device Physical Testing Procedures

Physical device testing validates actual radio performance in RF environments.

### Test 1: Android → Android
1. Open MeshConnect on Phone 1 and Phone 2. Turn off Wi-Fi and Cellular Data on both.
2. Confirm Bluetooth is enabled on both.
3. Observe Phone 2 appearing on Phone 1's Nearby Peers screen.
4. Send an encrypted message from Phone 1.
5. Verify Phone 2 receives the packet, displays `1 hop`, and sends back an ACK confirmation.

### Test 2: iPhone → iPhone
1. Open MeshConnect on iPhone 1 and iPhone 2 without Wi-Fi or Cellular internet.
2. Confirm both grant Local Network and Bluetooth permissions.
3. Verify peer discovery via MultipeerConnectivity.
4. Send message and observe `Delivered ✓`.

### Test 3: Android ↔ iPhone Cross-Platform
1. Position Android Phone and iPhone within 10 meters.
2. Both apps run the identical protocol and wire JSON formats.
3. Messages received by either device decrypt cleanly using matching AES-256-GCM and Ed25519 keys.

### Test 4: 3-Device Multi-Hop (A → B → C)
1. Place Phone A and Phone C out of direct Bluetooth range (e.g., 50 meters apart or behind walls).
2. Position Phone B equidistant between them as a relay.
3. Send a message from Phone A to Phone C.
4. Verify Phone B relays the packet (`hopCount = 1`).
5. Verify Phone C receives the packet (`hopCount = 2`) and returns an ACK through Phone B.

### Test 5: 4-Device Multi-Hop (A → B → C → D)
1. Line up 4 devices along a corridor.
2. Send packet from Node A destined for Node D.
3. Observe packet traversing B and C with TTL decrementing by 1 at each hop.
4. Node D receives the packet, displays 3 hops, and responds with an ACK.

### Test 6 & 7: Zero-Internet & Cellular Disabled Validation
1. Enable Airplane mode, then explicitly turn on Bluetooth only.
2. Verify full message creation, storage, discovery, and forwarding continue with zero network calls.

### Test 8: Self-Healing Mesh (Relay Device Removed)
1. Form active route: A → B → C → Destination.
2. Power off Device B or disable its Bluetooth.
3. Send a new message from Device A.
4. Verify Device A detects Device B's disconnection, invalidates the route, and recalculates forwarding via alternate Device E.

### Test 9: Emergency SOS Priority Propagation
1. Trigger Emergency SOS on Node A.
2. Verify the alert bypasses regular queues, uses priority `emergency` (TTL 15), and is broadcast to all reachable peers immediately.

---

## 3. Performance Telemetry

Use the in-app **Diagnostics Screen** to inspect real-time metrics:
- **Discovery Time**: Seconds from radio activation to initial peer beacon.
- **Hop Latency**: Measured round-trip delivery time per hop.
- **Relay Count**: Total multi-hop frames processed.
- **Duplicate Suppression Rate**: Total duplicate packets caught and dropped.
