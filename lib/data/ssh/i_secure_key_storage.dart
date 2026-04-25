import 'dart:typed_data';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';

abstract interface class ISecureKeyStorage {
  Future<Result<void, AppError>> storeKey(Uint8List keyBytes, {String? passphrase});
  Future<Result<SecureKey, AppError>> loadKey({String? passphrase});
  Future<Result<void, AppError>> deleteKey();
  Future<bool> hasKey();
}
