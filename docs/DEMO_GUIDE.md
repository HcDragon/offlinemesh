# MeshConnect Hackathon Live Demonstration Guide

This guide provides a structured 3-minute live demonstration flow for judges and hackathon presentations.

---

## 1. Opening Statement (30 seconds)
> *"When disaster strikes or critical infrastructure collapses, cellular towers and Wi-Fi networks go down. Standard messaging apps become useless. **MeshConnect** transforms everyday smartphones into a decentralized, multi-hop radio network. No internet, no cellular towers, no cloud servers required."*

---

## 2. Demonstration Flow

### Step 1: Prove Offline Architecture
1. Pull down the status bar on the demo phone and enable **Airplane Mode** (Cellular: OFF, Wi-Fi: OFF).
2. Enable Bluetooth only.
3. Open **MeshConnect**.
4. Point to the top banner: **`● Offline Mesh Mode: No Internet Required`**.

### Step 2: Open the Mesh Topology Map
1. Tap the **Mesh Map** tab in the bottom navigation.
2. Show the radar canvas with concentric rings.
3. Highlight the visual representation:
   - Light Blue center: Your phone (Local node)
   - Green nodes: Active 1-hop relay peers
   - Blue nodes: Shelter Node
   - Purple node: Rescue Gateway HQ
   - Glowing mesh links: Discovered peer-to-peer radio paths.

### Step 3: Launch the Multi-Node Simulator
1. Tap the **Simulation Sandbox** (flask icon in top right or Settings).
2. Point out the clear banner: **`SIMULATION / DEMO MODE`**.
3. Tap **Simulate Message Hop**:
   - Watch the packet illuminate **Node A (User Phone)**: creates Ed25519 signature & AES ciphertext.
   - 900ms later: **Node B (Volunteer 02)** relays frame, decrements TTL.
   - 900ms later: **Node C (Shelter Alpha)** forwards to gateway.
   - 1000ms later: **Node D (Rescue Gateway HQ)** receives message and returns an **ACK Confirmation ✓**.

### Step 4: Inspect Packet Telemetry (Packet Inspector)
1. Tap the message in the conversation thread to open the **Packet Inspector**.
2. Show the judges:
   - Wire headers: Message UUID, Protocol v1, Hop Count (`3 hops`), TTL Remaining (`4`).
   - Security verification: Authenticated AES-256-GCM + Ed25519 digital signature string.
   - Multi-Hop Audit Trail: `[node-A-user, node-B-volunteer, node-C-shelter]`.

### Step 5: Demonstrate Self-Healing Mesh
1. In the Multi-Node Simulator, toggle **Volunteer 02** to **OFFLINE**.
2. Explain: *"In an emergency, relay nodes move away or lose power. MeshConnect detects link breaks and recalculates alternative paths through nearby peers without dropping messages."*

### Step 6: Trigger Emergency SOS
1. Tap the prominent red **EMERGENCY SOS** button.
2. Select emergency type (e.g. *Medical Assistance*), attach GPS coordinates, and tap **BROADCAST EMERGENCY SOS**.
3. Point to the **Live Status Screen**:
   - `SOS CREATED & SIGNED`
   - `3 PEERS REACHED`
   - `RELAYED ACROSS MESH`
   - `RESCUE NODE RECEIVED ✓`

---

## 3. Closing Summary
> *"MeshConnect isn't just an app that works without internet. It is a resilient, decentralized communication system where the smartphones themselves become the network."*
