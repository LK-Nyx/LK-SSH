import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/server.dart';
import 'package:lk_ssh/data/models/settings.dart';
import 'package:lk_ssh/data/models/ssh_key.dart';
import 'package:lk_ssh/data/storage/json_storage_service.dart';

void main() {
  late Directory tmpDir;
  late JsonStorageService storage;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('lk_ssh_test_');
    storage = JsonStorageService(tmpDir);
  });

  tearDown(() => tmpDir.deleteSync(recursive: true));

  group('JsonStorageService', () {
    test('loadServers retourne liste vide si fichier absent', () async {
      final result = await storage.loadServers();
      expect(result.isOk, isTrue);
      expect(result.value, isEmpty);
    });

    test('saveServers puis loadServers roundtrip', () async {
      const server = Server(
        id: '1',
        label: 'prod',
        host: '10.0.0.1',
        port: 22,
        username: 'root',
      );
      await storage.saveServers([server]);
      final result = await storage.loadServers();
      expect(result.isOk, isTrue);
      expect(result.value.first, server);
    });

    test('loadSettings retourne Settings par défaut si absent', () async {
      final result = await storage.loadSettings();
      expect(result.isOk, isTrue);
      expect(result.value, const Settings());
    });

    test('fichier JSON corrompu est reset et retourne liste vide', () async {
      // Comportement délibéré du _loadList : on supprime le fichier corrompu
      // et on repart vide plutôt que de bloquer l'app au démarrage.
      final f = File('${tmpDir.path}/servers.json');
      await f.writeAsString('not json {{');
      final result = await storage.loadServers();
      expect(result.isOk, isTrue);
      expect(result.value, isEmpty);
      expect(await f.exists(), isFalse);
    });

    test('saveSshKeys puis loadSshKeys roundtrip', () async {
      final key = SshKey(
        id: 'k1',
        label: 'MacBook',
        addedAt: DateTime.utc(2026, 4, 27),
      );
      await storage.saveSshKeys([key]);
      final result = await storage.loadSshKeys();
      expect(result.isOk, isTrue);
      expect(result.value.first, key);
    });

    test('loadSshKeys retourne liste vide si fichier absent', () async {
      final result = await storage.loadSshKeys();
      expect(result.isOk, isTrue);
      expect(result.value, isEmpty);
    });
  });
}
