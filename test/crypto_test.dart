import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshconnect/crypto/crypto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cryptoService = CryptoService();

  group('Cryptographic Operations & Identity Tests', () {
    test('Should generate valid Ed25519 and X25519 keypairs', () async {
      final keyPair = await cryptoService.generateIdentityKeyPair();
      expect(keyPair.signingKeyPair, isNotNull);
      expect(keyPair.signingPublicKey, isNotNull);
      expect(keyPair.exchangeKeyPair, isNotNull);
      expect(keyPair.exchangePublicKey, isNotNull);

      final pubBytes = keyPair.signingPublicKey.bytes;
      expect(pubBytes.length, equals(32)); // Ed25519 public key is 32 bytes
    });

    test('Should sign message and verify valid signature with Ed25519', () async {
      final keyPair = await cryptoService.generateIdentityKeyPair();
      const message = 'MeshConnect: Decentralized emergency communication packet 2026';

      final signature = await cryptoService.signMessage(
        data: message,
        keyPair: keyPair.signingKeyPair,
      );
      expect(signature, isNotEmpty);

      final pubKeyBase64 = base64Encode(keyPair.signingPublicKey.bytes);
      final isValid = await cryptoService.verifySignature(
        data: message,
        signatureBase64: signature,
        publicKeyBase64: pubKeyBase64,
      );
      expect(isValid, isTrue);
    });

    test('Should reject tampered message with invalid signature', () async {
      final keyPair = await cryptoService.generateIdentityKeyPair();
      const message = 'Authentic medical dispatch packet';
      const tamperedMessage = 'Altered malicious message';

      final signature = await cryptoService.signMessage(
        data: message,
        keyPair: keyPair.signingKeyPair,
      );

      final pubKeyBase64 = base64Encode(keyPair.signingPublicKey.bytes);
      final isValid = await cryptoService.verifySignature(
        data: tamperedMessage,
        signatureBase64: signature,
        publicKeyBase64: pubKeyBase64,
      );
      expect(isValid, isFalse);
    });

    test('Should encrypt and decrypt payload with AES-256-GCM', () async {
      final secretKey = await cryptoService.getEmergencyBroadcastKey();
      const plainText = 'Urgent: Water purification tablets required at Shelter 3';

      final encryptedJson = await cryptoService.encryptPayload(
        plainText: plainText,
        secretKey: secretKey,
      );
      expect(encryptedJson, contains('cipher'));
      expect(encryptedJson, contains('nonce'));
      expect(encryptedJson, contains('mac'));

      final decrypted = await cryptoService.decryptPayload(
        encryptedJson: encryptedJson,
        secretKey: secretKey,
      );
      expect(decrypted, equals(plainText));
    });

    test('Should derive matching shared secret between Alice and Bob with X25519 ECDH', () async {
      final alice = await cryptoService.generateIdentityKeyPair();
      final bob = await cryptoService.generateIdentityKeyPair();

      final alicePubBase64 = base64Encode(alice.exchangePublicKey.bytes);
      final bobPubBase64 = base64Encode(bob.exchangePublicKey.bytes);

      final aliceDerivedKey = await cryptoService.deriveSharedSecret(
        myExchangeKeyPair: alice.exchangeKeyPair,
        peerExchangePublicKeyBase64: bobPubBase64,
      );

      final bobDerivedKey = await cryptoService.deriveSharedSecret(
        myExchangeKeyPair: bob.exchangeKeyPair,
        peerExchangePublicKeyBase64: alicePubBase64,
      );

      final aliceKeyBytes = await aliceDerivedKey.extractBytes();
      final bobKeyBytes = await bobDerivedKey.extractBytes();

      expect(aliceKeyBytes, equals(bobKeyBytes));
    });
  });
}
