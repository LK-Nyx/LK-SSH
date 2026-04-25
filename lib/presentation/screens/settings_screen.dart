import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/settings.dart';
import '../providers/secure_key_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: settingsAsync.when(
        data: (settings) => _SettingsBody(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({required this.settings});
  final Settings settings;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  bool _keyLoaded = false;
  String? _keyError;

  @override
  void initState() {
    super.initState();
    _checkKeyLoaded();
  }

  Future<void> _checkKeyLoaded() async {
    final storage = ref.read(secureKeyStorageProvider);
    final has = await storage.hasKey();
    if (mounted) setState(() => _keyLoaded = has);
  }

  Future<void> _importKey(String? passphrase) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    final bytes = await result.files.single.xFile.readAsBytes();
    final storage = ref.read(secureKeyStorageProvider);
    final storeResult = await storage.storeKey(
      Uint8List.fromList(bytes),
      passphrase: passphrase,
    );

    if (!mounted) return;
    storeResult.when(
      ok: (_) => setState(() {
        _keyLoaded = true;
        _keyError = null;
      }),
      err: (e) => setState(() => _keyError = e.toString()),
    );
  }

  void _onImportPressed() {
    if (widget.settings.keyStorageMode == KeyStorageMode.passphraseProtected) {
      _showPassphraseDialog();
    } else {
      _importKey(null);
    }
  }

  void _showPassphraseDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Passphrase'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Passphrase'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importKey(ctrl.text);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _SectionHeader('Stockage clé SSH'),
        RadioListTile<KeyStorageMode>(
          title: const Text('Mode A — Secure Storage'),
          value: KeyStorageMode.secureStorage,
          groupValue: widget.settings.keyStorageMode,
          onChanged: (v) => ref
              .read(settingsNotifierProvider.notifier)
              .save(widget.settings.copyWith(keyStorageMode: v!)),
        ),
        RadioListTile<KeyStorageMode>(
          title: const Text('Mode D — + Passphrase argon2id'),
          value: KeyStorageMode.passphraseProtected,
          groupValue: widget.settings.keyStorageMode,
          onChanged: (v) => ref
              .read(settingsNotifierProvider.notifier)
              .save(widget.settings.copyWith(keyStorageMode: v!)),
        ),
        const Divider(),
        const _SectionHeader('Clé privée ed25519'),
        ListTile(
          title: const Text('Importer via fichier'),
          subtitle: _keyError != null
              ? Text(_keyError!, style: const TextStyle(color: Colors.red))
              : _keyLoaded
                  ? const Text(
                      '✓ ed25519 chargée',
                      style: TextStyle(color: Color(0xFF00FF41)),
                    )
                  : const Text('Aucune clé chargée'),
          trailing: ElevatedButton(
            onPressed: _onImportPressed,
            child: const Text('Importer'),
          ),
        ),
        const Divider(),
        const _SectionHeader('Session'),
        ListTile(
          title: const Text('Timeout (minutes)'),
          trailing: DropdownButton<int>(
            value: widget.settings.sessionTimeoutMinutes,
            items: [1, 5, 10, 30, 60]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v min')))
                .toList(),
            onChanged: (v) => ref
                .read(settingsNotifierProvider.notifier)
                .save(widget.settings.copyWith(sessionTimeoutMinutes: v!)),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00FF41),
            fontFamily: 'monospace',
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      );
}
