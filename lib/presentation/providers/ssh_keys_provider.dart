import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/settings.dart';
import '../../data/models/ssh_key.dart';
import '../../data/ssh/i_ssh_key_registry.dart';
import '../../data/ssh/ssh_key_registry_a.dart';
import '../../data/ssh/ssh_key_registry_d.dart';
import 'settings_provider.dart';
import 'storage_provider.dart';
import 'vault_passphrase_provider.dart';

part 'ssh_keys_provider.g.dart';

@riverpod
Future<ISshKeyRegistry> sshKeyRegistry(Ref ref) async {
  final settings = ref.watch(settingsNotifierProvider).valueOrNull;
  if (settings?.keyStorageMode == KeyStorageMode.passphraseProtected) {
    final pp = ref.watch(vaultPassphraseProvider);
    if (pp == null) {
      throw StateError(
          'Mode D registry requested before unlock — bootstrap should have gated.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${dir.path}/lk_ssh_data');
    return SshKeyRegistryD(directory: dataDir, passphrase: pp);
  }
  return SshKeyRegistryA();
}

@riverpod
class SshKeysNotifier extends _$SshKeysNotifier {
  static const _uuid = Uuid();

  @override
  Future<List<SshKey>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final r = await storage.loadSshKeys();
    return switch (r) {
      Ok(:final value) => value,
      Err() => <SshKey>[],
    };
  }

  Future<Result<SshKey, AppError>> add({
    required String label,
    required Uint8List bytes,
    String? passphrase,
  }) async {
    final id = _uuid.v4();
    final entry = SshKey(id: id, label: label, addedAt: DateTime.now());
    final registry = await ref.read(sshKeyRegistryProvider.future);
    final saveR = await registry.save(keyId: id, bytes: bytes, passphrase: passphrase);
    switch (saveR) {
      case Err(:final error):
        return Err(error);
      case Ok():
        break;
    }
    final current = state.valueOrNull ?? const <SshKey>[];
    final next = [...current, entry];
    final storage = await ref.read(storageProvider.future);
    final saveMetaR = await storage.saveSshKeys(next);
    switch (saveMetaR) {
      case Err(:final error):
        await registry.delete(id);
        return Err(error);
      case Ok():
        state = AsyncData(next);
        return Ok(entry);
    }
  }

  Future<void> rename(String id, String newLabel) async {
    final current = state.valueOrNull ?? const <SshKey>[];
    final next = [
      for (final k in current)
        if (k.id == id) k.copyWith(label: newLabel) else k
    ];
    final storage = await ref.read(storageProvider.future);
    await storage.saveSshKeys(next);
    state = AsyncData(next);
  }

  Future<void> remove(String id) async {
    final registry = await ref.read(sshKeyRegistryProvider.future);
    await registry.delete(id);
    final current = state.valueOrNull ?? const <SshKey>[];
    final next = current.where((k) => k.id != id).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveSshKeys(next);
    state = AsyncData(next);
  }
}
