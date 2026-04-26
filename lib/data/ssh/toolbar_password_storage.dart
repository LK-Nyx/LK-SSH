import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class ToolbarPasswordStorage {
  static const _key = 'toolbar_password';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> load() => _storage.read(key: _key);

  Future<void> save(String password) =>
      _storage.write(key: _key, value: password);

  Future<void> delete() => _storage.delete(key: _key);
}
