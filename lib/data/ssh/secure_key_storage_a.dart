import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import 'i_secure_key_storage.dart';

final class SecureKeyStorageA implements ISecureKeyStorage {
  static const _keyName = 'ssh_private_key_b64';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<Result<void, AppError>> storeKey(
    Uint8List keyBytes, {
    String? passphrase,
  }) async {
    try {
      await _storage.write(key: _keyName, value: base64Encode(keyBytes));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<SecureKey, AppError>> loadKey({String? passphrase}) async {
    try {
      final value = await _storage.read(key: _keyName);
      if (value == null) return const Err(KeyNotFoundError());
      return Ok(SecureKey.fromBytes(base64Decode(value)));
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> deleteKey() async {
    await _storage.delete(key: _keyName);
    return const Ok(null);
  }

  @override
  Future<bool> hasKey() async {
    final value = await _storage.read(key: _keyName);
    return value != null;
  }
}
