import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'crypto_service.dart';

class KeyManager {
  static final KeyManager _instance = KeyManager._internal();
  factory KeyManager() => _instance;
  KeyManager._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyMeshId = 'mesh_id';
  static const String _keyDisplayName = 'display_name';
  static const String _keySignPriv = 'sec_sign_priv';
  static const String _keySignPub = 'sec_sign_pub';
  static const String _keyExchPriv = 'sec_exch_priv';
  static const String _keyExchPub = 'sec_exch_pub';

  String? _meshId;
  String? _displayName;
  SimpleKeyPair? _signingKeyPair;
  String? _signingPublicKeyBase64;
  SimpleKeyPair? _exchangeKeyPair;
  String? _exchangePublicKeyBase64;

  String get meshId => _meshId ?? 'node-unknown';
  String get displayName => _displayName ?? 'My Node';
  SimpleKeyPair? get signingKeyPair => _signingKeyPair;
  String get signingPublicKeyBase64 => _signingPublicKeyBase64 ?? '';
  SimpleKeyPair? get exchangeKeyPair => _exchangeKeyPair;
  String get exchangePublicKeyBase64 => _exchangePublicKeyBase64 ?? '';

  Future<void> initialize({String? customDisplayName}) async {
    _meshId = await _secureStorage.read(key: _keyMeshId);
    _displayName = await _secureStorage.read(key: _keyDisplayName);

    if (_meshId == null) {
      // First boot: Generate cryptographic identity
      final shortUuid = const Uuid().v4().substring(0, 8);
      _meshId = 'node-$shortUuid';
      _displayName = customDisplayName ?? 'User-${shortUuid.substring(0, 4).toUpperCase()}';

      final keyPair = await CryptoService().generateIdentityKeyPair();
      _signingKeyPair = keyPair.signingKeyPair;
      _exchangeKeyPair = keyPair.exchangeKeyPair;

      _signingPublicKeyBase64 = base64Encode(keyPair.signingPublicKey.bytes);
      _exchangePublicKeyBase64 = base64Encode(keyPair.exchangePublicKey.bytes);

      final signPrivData = await keyPair.signingKeyPair.extract();
      final exchPrivData = await keyPair.exchangeKeyPair.extract();

      await _secureStorage.write(key: _keyMeshId, value: _meshId);
      await _secureStorage.write(key: _keyDisplayName, value: _displayName);
      await _secureStorage.write(key: _keySignPriv, value: base64Encode(signPrivData.bytes));
      await _secureStorage.write(key: _keySignPub, value: _signingPublicKeyBase64);
      await _secureStorage.write(key: _keyExchPriv, value: base64Encode(exchPrivData.bytes));
      await _secureStorage.write(key: _keyExchPub, value: _exchangePublicKeyBase64);
    } else {
      // Restore existing identity
      _signingPublicKeyBase64 = await _secureStorage.read(key: _keySignPub);
      _exchangePublicKeyBase64 = await _secureStorage.read(key: _keyExchPub);

      final signPrivBase64 = await _secureStorage.read(key: _keySignPriv);
      final exchPrivBase64 = await _secureStorage.read(key: _keyExchPriv);

      if (signPrivBase64 != null && _signingPublicKeyBase64 != null) {
        _signingKeyPair = SimpleKeyPairData(
          base64Decode(signPrivBase64),
          publicKey: SimplePublicKey(base64Decode(_signingPublicKeyBase64!), type: KeyPairType.ed25519),
          type: KeyPairType.ed25519,
        );
      }

      if (exchPrivBase64 != null && _exchangePublicKeyBase64 != null) {
        _exchangeKeyPair = SimpleKeyPairData(
          base64Decode(exchPrivBase64),
          publicKey: SimplePublicKey(base64Decode(_exchangePublicKeyBase64!), type: KeyPairType.x25519),
          type: KeyPairType.x25519,
        );
      }
    }
  }

  Future<void> updateDisplayName(String newName) async {
    _displayName = newName;
    await _secureStorage.write(key: _keyDisplayName, value: newName);
  }
}
