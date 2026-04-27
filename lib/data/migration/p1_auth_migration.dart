import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import '../models/auth_method.dart';
import '../models/ssh_key.dart';
import '../ssh/i_secure_key_storage.dart';
import '../ssh/i_ssh_key_registry.dart';
import '../storage/i_storage_service.dart';

abstract interface class LegacyKeyReader {
  Future<bool> hasKey();
  Future<Result<SecureKey, AppError>> loadKey();
}

final class LegacyKeyReaderImpl implements LegacyKeyReader {
  LegacyKeyReaderImpl(this._storage) : _passphrase = null;
  LegacyKeyReaderImpl.modeD(this._storage, String passphrase)
      : _passphrase = passphrase;

  final ISecureKeyStorage _storage;
  final String? _passphrase;

  @override
  Future<bool> hasKey() => _storage.hasKey();

  @override
  Future<Result<SecureKey, AppError>> loadKey() =>
      _storage.loadKey(passphrase: _passphrase);
}

class P1AuthMigration {
  P1AuthMigration({
    required this.storage,
    required this.registry,
    required this.legacy,
  });

  final IStorageService storage;
  final ISshKeyRegistry registry;
  final LegacyKeyReader legacy;

  static const defaultKeyId = 'default';

  Future<void> run() async {
    final settingsR = await storage.loadSettings();
    final settings = switch (settingsR) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (settings == null || settings.migrationP1Done) return;

    if (!await legacy.hasKey()) {
      await storage.saveSettings(settings.copyWith(migrationP1Done: true));
      return;
    }

    final keyR = await legacy.loadKey();
    final secureKey = switch (keyR) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (secureKey == null) return; // bootstrap should have unlocked; retry next boot.

    final saveBytes = await registry.save(
      keyId: defaultKeyId,
      bytes: secureKey.bytes,
    );
    if (saveBytes is Err) return;

    final keys = switch (await storage.loadSshKeys()) {
      Ok(:final value) => value,
      Err() => <SshKey>[],
    };
    if (!keys.any((k) => k.id == defaultKeyId)) {
      await storage.saveSshKeys([
        ...keys,
        SshKey(
          id: defaultKeyId,
          label: 'Clé par défaut',
          addedAt: DateTime.now(),
        ),
      ]);
    }

    final serversR = await storage.loadServers();
    if (serversR case Ok(:final value)) {
      final retagged = value
          .map((s) =>
              s.copyWith(authMethod: AuthMethod.key, keyId: defaultKeyId))
          .toList();
      await storage.saveServers(retagged);
    }

    await storage.saveSettings(settings.copyWith(migrationP1Done: true));
  }
}
