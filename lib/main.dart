import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'core/result.dart';
import 'data/migration/p1_auth_migration.dart';
import 'data/models/settings.dart';
import 'data/ssh/secure_key_storage_a.dart';
import 'data/ssh/secure_key_storage_d.dart';
import 'data/ssh/ssh_key_registry_a.dart';
import 'data/ssh/ssh_key_registry_d.dart';
import 'data/storage/debug_log_service.dart';
import 'data/storage/json_storage_service.dart';
import 'presentation/design/theme/app_theme.dart' as ds;
import 'presentation/providers/vault_passphrase_provider.dart';
import 'presentation/screens/server_list_screen.dart';
import 'presentation/screens/unlock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final dataDir = Directory('${dir.path}/lk_ssh_data');
  if (!await dataDir.exists()) await dataDir.create(recursive: true);

  final storage = JsonStorageService(dataDir);
  final settingsR = await storage.loadSettings();
  final settings = switch (settingsR) {
    Ok(:final value) => value,
    Err() => const Settings(),
  };
  if (settings.fileDebugMode) await DebugLogService.instance.setEnabled(true);

  final container = ProviderContainer();

  if (settings.keyStorageMode == KeyStorageMode.passphraseProtected) {
    // Mode D: gate the app behind UnlockScreen if there is anything to unlock.
    final vaultFile = File('${dataDir.path}/key_vault.bin');
    final hasVault = await vaultFile.exists();
    final hasLegacy = await SecureKeyStorageD().hasKey();
    if (hasVault || hasLegacy) {
      runApp(UncontrolledProviderScope(
        container: container,
        child: _UnlockGate(
          dataDir: dataDir,
          hasVault: hasVault,
          hasLegacy: hasLegacy,
          onUnlocked: (passphrase) async {
            container.read(vaultPassphraseProvider.notifier).unlock(passphrase);
            await _runMigration(container, dataDir, isModeD: true);
          },
        ),
      ));
      return;
    }
  }

  // Mode A (or mode D with nothing to unlock yet): run migration + go.
  await _runMigration(container, dataDir, isModeD: false);
  runApp(UncontrolledProviderScope(
    container: container,
    child: const LkSshApp(),
  ));
}

Future<void> _runMigration(
  ProviderContainer container,
  Directory dataDir, {
  required bool isModeD,
}) async {
  final storage = JsonStorageService(dataDir);
  final passphrase = container.read(vaultPassphraseProvider) ?? '';
  final registry = isModeD
      ? SshKeyRegistryD(directory: dataDir, passphrase: passphrase)
      : SshKeyRegistryA();
  final legacy = isModeD
      ? LegacyKeyReaderImpl.modeD(SecureKeyStorageD(), passphrase)
      : LegacyKeyReaderImpl(SecureKeyStorageA());
  await P1AuthMigration(
    storage: storage,
    registry: registry,
    legacy: legacy,
  ).run();
}

class _UnlockGate extends ConsumerStatefulWidget {
  const _UnlockGate({
    required this.dataDir,
    required this.hasVault,
    required this.hasLegacy,
    required this.onUnlocked,
  });

  final Directory dataDir;
  final bool hasVault;
  final bool hasLegacy;
  final Future<void> Function(String passphrase) onUnlocked;

  @override
  ConsumerState<_UnlockGate> createState() => _UnlockGateState();
}

class _UnlockGateState extends ConsumerState<_UnlockGate> {
  bool _unlocked = false;

  Future<bool> _verify(String passphrase) async {
    if (widget.hasVault) {
      final reg = SshKeyRegistryD(
        directory: widget.dataDir,
        passphrase: passphrase,
      );
      // Probing any keyId either returns Ok (with the key) or KeyNotFound
      // (vault decrypted, key missing) — both prove the passphrase.
      // KeyDecryptionError proves wrong passphrase.
      final probe = await reg.loadBytes('__probe__');
      switch (probe) {
        case Ok():
          return true;
        case Err(:final error):
          return error.runtimeType.toString() != 'KeyDecryptionError';
      }
    }
    if (widget.hasLegacy) {
      final r = await SecureKeyStorageD().loadKey(passphrase: passphrase);
      switch (r) {
        case Ok():
          return true;
        case Err(:final error):
          return error.runtimeType.toString() != 'KeyDecryptionError';
      }
    }
    return passphrase.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return const LkSshApp();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ds.AppTheme.dark(),
      home: UnlockScreen(
        onSubmit: (passphrase) async {
          final ok = await _verify(passphrase);
          if (!ok) return false;
          await widget.onUnlocked(passphrase);
          if (mounted) setState(() => _unlocked = true);
          return true;
        },
      ),
    );
  }
}

class LkSshApp extends ConsumerWidget {
  const LkSshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LK-SSH',
      debugShowCheckedModeBanner: false,
      theme: ds.AppTheme.dark(),
      home: const ServerListScreen(),
    );
  }
}
