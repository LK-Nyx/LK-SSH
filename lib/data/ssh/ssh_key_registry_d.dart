import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import 'i_ssh_key_registry.dart';

final class SshKeyRegistryD implements ISshKeyRegistry {
  SshKeyRegistryD({required Directory directory, required String passphrase})
      : _file = File('${directory.path}/key_vault.bin'),
        _passphrase = passphrase;

  final File _file;
  final String _passphrase;

  // Same parameters as SecureKeyStorageD — keep the user passphrase compatible.
  static final _argon2id = Argon2id(
    memory: 65536,
    parallelism: 2,
    iterations: 3,
    hashLength: 32,
  );
  static const _saltLen = 32;

  Future<SecretKey> _deriveKey(List<int> salt) => _argon2id.deriveKey(
        secretKey: SecretKey(utf8.encode(_passphrase)),
        nonce: salt,
      );

  Uint8List _randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
  }

  /// Returns Ok(empty map) if vault doesn't exist.
  /// Returns Err(KeyDecryptionError) if it exists but the passphrase is wrong.
  Future<Result<Map<String, Map<String, dynamic>>, AppError>> _loadVault() async {
    if (!await _file.exists()) return const Ok(<String, Map<String, dynamic>>{});
    try {
      final raw = await _file.readAsBytes();
      if (raw.length <= _saltLen) return const Err(KeyDecryptionError());
      final salt = raw.sublist(0, _saltLen);
      final blob = raw.sublist(_saltLen);
      final aesGcm = AesGcm.with256bits();
      final box = SecretBox.fromConcatenation(
        blob,
        nonceLength: aesGcm.nonceLength,
        macLength: aesGcm.macAlgorithm.macLength,
      );
      final secretKey = await _deriveKey(salt);
      final decrypted = await aesGcm.decrypt(box, secretKey: secretKey);
      final json = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      return Ok(json.map((k, v) => MapEntry(k, (v as Map).cast<String, dynamic>())));
    } on SecretBoxAuthenticationError {
      return const Err(KeyDecryptionError());
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  Future<Result<void, AppError>> _writeVault(
      Map<String, Map<String, dynamic>> vault) async {
    try {
      final salt = _randomBytes(_saltLen);
      final secretKey = await _deriveKey(salt);
      final aesGcm = AesGcm.with256bits();
      final plaintext = utf8.encode(jsonEncode(vault));
      final box = await aesGcm.encrypt(plaintext, secretKey: secretKey);
      final blob = Uint8List.fromList([...salt, ...box.concatenation()]);
      // Atomic write: tmp then rename.
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsBytes(blob, flush: true);
      await tmp.rename(_file.path);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> save({
    required String keyId,
    required Uint8List bytes,
    String? passphrase,
  }) async {
    final loaded = await _loadVault();
    switch (loaded) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        final next = Map<String, Map<String, dynamic>>.from(value);
        next[keyId] = {
          'bytes': base64Encode(bytes),
          if (passphrase != null) 'passphrase': passphrase,
        };
        return _writeVault(next);
    }
  }

  @override
  Future<Result<SecureKey, AppError>> loadBytes(String keyId) async {
    final loaded = await _loadVault();
    switch (loaded) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        final entry = value[keyId];
        if (entry == null) return const Err(KeyNotFoundError());
        final bytes = base64Decode(entry['bytes'] as String);
        return Ok(SecureKey.fromBytes(bytes));
    }
  }

  @override
  Future<String?> loadPassphrase(String keyId) async {
    final loaded = await _loadVault();
    switch (loaded) {
      case Err():
        return null;
      case Ok(:final value):
        return value[keyId]?['passphrase'] as String?;
    }
  }

  @override
  Future<Result<void, AppError>> delete(String keyId) async {
    final loaded = await _loadVault();
    switch (loaded) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        if (!value.containsKey(keyId)) return const Ok(null);
        final next = Map<String, Map<String, dynamic>>.from(value)..remove(keyId);
        return _writeVault(next);
    }
  }
}
