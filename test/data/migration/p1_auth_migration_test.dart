import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/result.dart';
import 'package:lk_ssh/core/secure_key.dart';
import 'package:lk_ssh/data/migration/p1_auth_migration.dart';
import 'package:lk_ssh/data/models/auth_method.dart';
import 'package:lk_ssh/data/models/server.dart';
import 'package:lk_ssh/data/models/settings.dart';
import 'package:lk_ssh/data/models/ssh_key.dart';
import 'package:lk_ssh/data/ssh/i_ssh_key_registry.dart';
import 'package:lk_ssh/data/storage/i_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements IStorageService {}

class _MockRegistry extends Mock implements ISshKeyRegistry {}

class _MockLegacy extends Mock implements LegacyKeyReader {}

void main() {
  setUpAll(() {
    registerFallbackValue(<Server>[]);
    registerFallbackValue(<SshKey>[]);
    registerFallbackValue(const Settings());
    registerFallbackValue(Uint8List(0));
  });

  late _MockStorage storage;
  late _MockRegistry registry;
  late _MockLegacy legacy;

  setUp(() {
    storage = _MockStorage();
    registry = _MockRegistry();
    legacy = _MockLegacy();
  });

  test('skips when migrationP1Done is already true', () async {
    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings(migrationP1Done: true)));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();

    verifyNever(() => storage.saveServers(any()));
    verifyNever(() => storage.saveSshKeys(any()));
    verifyNever(() => registry.save(
        keyId: any(named: 'keyId'),
        bytes: any(named: 'bytes'),
        passphrase: any(named: 'passphrase')));
  });

  test('skips and sets flag when no legacy key exists', () async {
    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings()));
    when(() => legacy.hasKey()).thenAnswer((_) async => false);
    when(() => storage.saveSettings(any()))
        .thenAnswer((_) async => const Ok(null));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();

    verify(() => storage.saveSettings(
        any(that: predicate<Settings>((s) => s.migrationP1Done)))).called(1);
    verifyNever(() => registry.save(
        keyId: any(named: 'keyId'),
        bytes: any(named: 'bytes'),
        passphrase: any(named: 'passphrase')));
  });

  test('migrates: creates default SshKey, registers bytes, retags servers', () async {
    final servers = [
      const Server(id: 's1', label: 'a', host: 'h', username: 'u'),
      const Server(id: 's2', label: 'b', host: 'h2', username: 'u'),
    ];
    final bytes = Uint8List.fromList([1, 2, 3]);

    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings()));
    when(() => legacy.hasKey()).thenAnswer((_) async => true);
    when(() => legacy.loadKey())
        .thenAnswer((_) async => Ok(SecureKey.fromBytes(bytes)));
    when(() => storage.loadServers()).thenAnswer((_) async => Ok(servers));
    when(() => storage.loadSshKeys()).thenAnswer((_) async => const Ok([]));
    when(() => storage.saveSshKeys(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => storage.saveServers(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => storage.saveSettings(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => registry.save(
        keyId: any(named: 'keyId'),
        bytes: any(named: 'bytes'),
        passphrase: any(named: 'passphrase')))
        .thenAnswer((_) async => const Ok(null));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();

    final savedKeys =
        verify(() => storage.saveSshKeys(captureAny())).captured.single
            as List<SshKey>;
    expect(savedKeys, hasLength(1));
    expect(savedKeys.first.id, 'default');
    expect(savedKeys.first.label, 'Clé par défaut');

    verify(() => registry.save(keyId: 'default', bytes: bytes)).called(1);

    final savedServers =
        verify(() => storage.saveServers(captureAny())).captured.single
            as List<Server>;
    expect(
        savedServers
            .every((s) => s.authMethod == AuthMethod.key && s.keyId == 'default'),
        isTrue);

    verify(() => storage.saveSettings(
        any(that: predicate<Settings>((s) => s.migrationP1Done)))).called(1);
  });

  test('idempotent: running twice is a no-op the second time', () async {
    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings(migrationP1Done: true)));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();
    await mig.run();
    verifyNever(() => storage.saveServers(any()));
  });
}
