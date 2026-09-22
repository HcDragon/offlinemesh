# MeshConnect Security Architecture & Threat Model

## 1. Cryptographic Primitives

MeshConnect employs standard, peer-reviewed cryptographic primitives:

| Component | Primitive | Purpose |
|---|---|---|
| **Payload Encryption** | AES-256-GCM (Authenticated Encryption with Associated Data) | Ensures confidentiality and integrity of message and SOS contents. |
| **Digital Signatures** | Ed25519 (Edwards-curve Digital Signature Algorithm) | Provides verifiable non-repudiation and origin authentication. |
| **Key Agreement** | X25519 Diffie-Hellman (ECDH) | Securely derives symmetric AES-256 session keys between peers. |
| **Integrity Hashing** | SHA-256 | Computes message digests and key derivations. |

---

## 2. Key Management & Hardware Security

### Storage:
- **Android**: Private signing and exchange keys are encrypted using Android Keystore via EncryptedSharedPreferences (`flutter_secure_storage`).
- **iOS**: Keys are stored in the iOS Keychain with `kSecAttrAccessibleAfterFirstUnlock`.

### Zero-Plaintext Logging Policy:
- Cryptographic keys, seeds, and unencrypted sensitive payloads are **strictly excluded** from debug and telemetry logs.
- The `MeshLogger` implementation automatically sanitizes all metadata dictionaries, redacting any key containing `key`, `secret`, `password`, or `plaintext`.

---

## 3. Replay Attack Prevention

Every packet contains:
1. A unique UUID v4 `messageId`.
2. A random 128-bit cryptographic `nonce`.
3. A creation timestamp `createdAt`.

**Verification Pipeline**:
- Packets with timestamps older than 24 hours or more than 10 minutes in the future are discarded.
- Duplicate message IDs and nonces are dropped by the `DeduplicationManager` cache before cryptographic verification or state mutation.

---

## 4. Privacy & Anonymity

- Devices do not broadcast phone numbers, IMEI, MAC addresses, Google Advertising IDs, or Apple ID credentials.
- Nodes identify exclusively via self-generated pseudonymous Mesh IDs (`node-xxxxxxxx`) and public keys.
- GPS coordinates are optional and shared only during explicit user action or Emergency SOS activation.
