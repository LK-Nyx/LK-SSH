import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import 'i_ssh_key_registry.dart';

final class SshKeyRegistryA implements ISshKeyRegistry {
  SshKeyRegistryA()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  SshKeyRegistryA.forTest(this._storage);

  final FlutterSecureStorage _storage;

  String _keyName(String id) => 'key_$id';
  String _ppName(String id) => 'pp_$id';

  @override
  Future<Result<void, AppError>> save({
    required String keyId,
    required Uint8List bytes,
    String? passphrase,
  }) async {
    try {
      await _storage.write(key: _keyName(keyId), value: base64Encode(bytes));
      if (passphrase == null) {
        await _storage.delete(key: _ppName(keyId));
      } else {
        await _storage.write(key: _ppName(keyId), value: passphrase);
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<SecureKey, AppError>> loadBytes(String keyId) async {
    try {
      final raw = await _storage.read(key: _keyName(keyId));
      if (raw == null) return const Err(KeyNotFoundError());
      return Ok(SecureKey.fromBytes(base64Decode(raw)));
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<String?> loadPassphrase(String keyId) =>
      _storage.read(key: _ppName(keyId));

  @override
  Future<Result<void, AppError>> delete(String keyId) async {
    try {
      await _storage.delete(key: _keyName(keyId));
      await _storage.delete(key: _ppName(keyId));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }
}
