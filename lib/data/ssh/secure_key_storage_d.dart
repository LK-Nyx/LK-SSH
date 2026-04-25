import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import 'i_secure_key_storage.dart';

final class SecureKeyStorageD implements ISecureKeyStorage {
  static const _encKeyName = 'ssh_key_enc_d';
  static const _saltName = 'ssh_key_salt_d';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final _argon2id = Argon2id(
    memory: 65536,
    parallelism: 2,
    iterations: 3,
    hashLength: 32,
  );

  Uint8List _randomBytes(int length) {
    final rand = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rand.nextInt(256)));
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) =>
      _argon2id.deriveKey(
        secretKey: SecretKey(utf8.encode(passphrase)),
        nonce: salt,
      );

  @override
  Future<Result<void, AppError>> storeKey(
    Uint8List keyBytes, {
    String? passphrase,
  }) async {
    if (passphrase == null || passphrase.isEmpty) {
      return const Err(KeyDecryptionError());
    }
    try {
      final salt = _randomBytes(32);
      final secretKey = await _deriveKey(passphrase, salt);
      final aesGcm = AesGcm.with256bits();
      final box = await aesGcm.encrypt(keyBytes, secretKey: secretKey);
      await _storage.write(
        key: _encKeyName,
        value: base64Encode(box.concatenation()),
      );
      await _storage.write(key: _saltName, value: base64Encode(salt));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<SecureKey, AppError>> loadKey({String? passphrase}) async {
    if (passphrase == null || passphrase.isEmpty) {
      return const Err(KeyDecryptionError());
    }
    try {
      final encValue = await _storage.read(key: _encKeyName);
      final saltValue = await _storage.read(key: _saltName);
      if (encValue == null || saltValue == null) return const Err(KeyNotFoundError());

      final salt = base64Decode(saltValue);
      final secretKey = await _deriveKey(passphrase, salt);
      final aesGcm = AesGcm.with256bits();
      final box = SecretBox.fromConcatenation(
        base64Decode(encValue),
        nonceLength: aesGcm.nonceLength,
        macLength: aesGcm.macAlgorithm.macLength,
      );
      final decrypted = await aesGcm.decrypt(box, secretKey: secretKey);
      return Ok(SecureKey.fromBytes(Uint8List.fromList(decrypted)));
    } on SecretBoxAuthenticationError {
      return const Err(KeyDecryptionError());
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> deleteKey() async {
    await Future.wait([
      _storage.delete(key: _encKeyName),
      _storage.delete(key: _saltName),
    ]);
    return const Ok(null);
  }

  @override
  Future<bool> hasKey() async {
    final value = await _storage.read(key: _encKeyName);
    return value != null;
  }
}
