import 'dart:typed_data';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';

abstract interface class ISshKeyRegistry {
  /// Stores key bytes (and optional passphrase) under [keyId].
  /// Caller is responsible for generating [keyId] (UUID).
  Future<Result<void, AppError>> save({
    required String keyId,
    required Uint8List bytes,
    String? passphrase,
  });

  /// Loads the key bytes for [keyId]. Returns `KeyNotFoundError` if absent.
  Future<Result<SecureKey, AppError>> loadBytes(String keyId);

  /// Loads the optional passphrase for [keyId]. Returns null if no passphrase
  /// was stored (key was unencrypted at import time).
  Future<String?> loadPassphrase(String keyId);

  Future<Result<void, AppError>> delete(String keyId);
}
