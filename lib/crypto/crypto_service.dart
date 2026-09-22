import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../core/errors/mesh_exception.dart';

class CryptoKeyPair {
  final SimpleKeyPair signingKeyPair;
  final SimplePublicKey signingPublicKey;
  final SimpleKeyPair exchangeKeyPair;
  final SimplePublicKey exchangePublicKey;

  CryptoKeyPair({
    required this.signingKeyPair,
    required this.signingPublicKey,
    required this.exchangeKeyPair,
    required this.exchangePublicKey,
  });
}

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final Ed25519 _ed25519 = Ed25519();
  final X25519 _x25519 = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();

  /// Generates a new cryptographic identity pair (Ed25519 for signing, X25519 for encryption)
  Future<CryptoKeyPair> generateIdentityKeyPair() async {
    final signingKeyPair = await _ed25519.newKeyPair();
    final signingPublicKey = await signingKeyPair.extractPublicKey();

    final exchangeKeyPair = await _x25519.newKeyPair();
    final exchangePublicKey = await exchangeKeyPair.extractPublicKey();

    return CryptoKeyPair(
      signingKeyPair: signingKeyPair,
      signingPublicKey: signingPublicKey,
      exchangeKeyPair: exchangeKeyPair,
      exchangePublicKey: exchangePublicKey,
    );
  }

  /// Sign message bytes with Ed25519 private key
  Future<String> signMessage({
    required String data,
    required SimpleKeyPair keyPair,
  }) async {
    try {
      final bytes = utf8.encode(data);
      final signature = await _ed25519.sign(bytes, keyPair: keyPair);
      return base64Encode(signature.bytes);
    } catch (e) {
      throw EncryptionException('Failed to sign message: $e');
    }
  }

  /// Verify Ed25519 signature
  Future<bool> verifySignature({
    required String data,
    required String signatureBase64,
    required String publicKeyBase64,
  }) async {
    try {
      final dataBytes = utf8.encode(data);
      final signatureBytes = base64Decode(signatureBase64);
      final publicKeyBytes = base64Decode(publicKeyBase64);

      final signature = Signature(
        signatureBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      );

      return await _ed25519.verify(dataBytes, signature: signature);
    } catch (_) {
      return false;
    }
  }

  /// Encrypt payload using AES-256-GCM with a pre-shared or derived key
  Future<String> encryptPayload({
    required String plainText,
    required SecretKey secretKey,
  }) async {
    try {
      final plainBytes = utf8.encode(plainText);
      final secretBox = await _aesGcm.encrypt(
        plainBytes,
        secretKey: secretKey,
      );

      final payloadMap = {
        'cipher': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };

      return jsonEncode(payloadMap);
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt payload using AES-256-GCM
  Future<String> decryptPayload({
    required String encryptedJson,
    required SecretKey secretKey,
  }) async {
    try {
      final map = jsonDecode(encryptedJson) as Map<String, dynamic>;
      final cipherText = base64Decode(map['cipher'] as String);
      final nonce = base64Decode(map['nonce'] as String);
      final mac = Mac(base64Decode(map['mac'] as String));

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: mac,
      );

      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Perform X25519 ECDH key agreement to derive an AES-256 secret key
  Future<SecretKey> deriveSharedSecret({
    required SimpleKeyPair myExchangeKeyPair,
    required String peerExchangePublicKeyBase64,
  }) async {
    try {
      final peerPublicKeyBytes = base64Decode(peerExchangePublicKeyBase64);
      final peerPublicKey = SimplePublicKey(peerPublicKeyBytes, type: KeyPairType.x25519);

      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: myExchangeKeyPair,
        remotePublicKey: peerPublicKey,
      );

      return sharedSecret;
    } catch (e) {
      throw EncryptionException('Key agreement failed: $e');
    }
  }

  /// Derive a deterministic emergency broadcast AES key for SOS / local announcements
  Future<SecretKey> getEmergencyBroadcastKey() async {
    final seed = utf8.encode('MeshConnect-Emergency-Broadcast-Key-v1-Global-2026');
    final hash = await Sha256().hash(seed);
    return SecretKey(hash.bytes);
  }
}
