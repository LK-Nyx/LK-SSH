import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'i_password_storage.dart';

final class SecurePasswordStorage implements IPasswordStorage {
  SecurePasswordStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  SecurePasswordStorage.forTest(this._storage);

  final FlutterSecureStorage _storage;

  String _key(String serverId) => 'pwd_$serverId';

  @override
  Future<String?> load(String serverId) => _storage.read(key: _key(serverId));

  @override
  Future<void> save(String serverId, String password) =>
      _storage.write(key: _key(serverId), value: password);

  @override
  Future<void> delete(String serverId) => _storage.delete(key: _key(serverId));
}
