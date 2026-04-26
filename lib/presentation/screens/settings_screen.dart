import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/settings.dart';
import '../../data/ssh/toolbar_password_storage.dart';
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

  final _pwStorage = ToolbarPasswordStorage();
  final _pwCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkKeyLoaded();
    _pwStorage.load().then((pw) {
      if (mounted && pw != null && pw.isNotEmpty) {
        _pwCtrl.text = '••••••••';
      }
    });
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkKeyLoaded() async {
    final storage = ref.read(secureKeyStorageProvider);
    final has = await storage.hasKey();
    if (mounted) setState(() => _keyLoaded = has);
  }

  Future<void> _storeKeyBytes(Uint8List bytes, String? passphrase) async {
    final storage = ref.read(secureKeyStorageProvider);
    final storeResult = await storage.storeKey(bytes, passphrase: passphrase);
    if (!mounted) return;
    storeResult.when(
      ok: (_) => setState(() {
        _keyLoaded = true;
        _keyError = null;
      }),
      err: (e) => setState(() => _keyError = e.toString()),
    );
  }

  Future<void> _importKeyFromFile(String? passphrase) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final bytes = await result.files.single.xFile.readAsBytes();
    await _storeKeyBytes(Uint8List.fromList(bytes), passphrase);
  }

  Future<void> _importKeyFromPem(String? passphrase) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Coller la clé PEM'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          decoration: const InputDecoration(
            hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final bytes = Uint8List.fromList(ctrl.text.trim().codeUnits);
    await _storeKeyBytes(bytes, passphrase);
  }

  void _onImportFilePressed() {
    if (widget.settings.keyStorageMode == KeyStorageMode.passphraseProtected) {
      _showPassphraseDialog(onConfirm: _importKeyFromFile);
    } else {
      _importKeyFromFile(null);
    }
  }

  void _onPastePressed() {
    if (widget.settings.keyStorageMode == KeyStorageMode.passphraseProtected) {
      _showPassphraseDialog(onConfirm: _importKeyFromPem);
    } else {
      _importKeyFromPem(null);
    }
  }

  void _showPassphraseDialog({required void Function(String?) onConfirm}) {
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
              onConfirm(ctrl.text);
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
        if (_keyError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(_keyError!, style: const TextStyle(color: Colors.red)),
          )
        else if (_keyLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '✓ ed25519 chargée',
              style: TextStyle(color: Color(0xFF00FF41)),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Aucune clé chargée',
                style: TextStyle(color: Colors.grey)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _onImportFilePressed,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Fichier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _onPastePressed,
                  icon: const Icon(Icons.content_paste, size: 16),
                  label: const Text('Coller PEM'),
                ),
              ),
            ],
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
        const Divider(),
        const _SectionHeader('Débogage'),
        SwitchListTile(
          title: const Text('Mode verbose'),
          subtitle: const Text(
            'Affiche les étapes de connexion SSH dans le terminal',
          ),
          value: widget.settings.verboseLogging,
          activeColor: const Color(0xFF00FF41),
          onChanged: (v) => ref
              .read(settingsNotifierProvider.notifier)
              .save(widget.settings.copyWith(verboseLogging: v)),
        ),
        const Divider(),
        const _SectionHeader('Barre clavier'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _pwCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe (touche 🔑)',
              border: OutlineInputBorder(),
              helperText: 'Envoyé tel quel au shell via la touche mot de passe',
            ),
            onSubmitted: (pw) async {
              if (pw.isNotEmpty) {
                await _pwStorage.save(pw);
                if (mounted) setState(() {});
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final pw = _pwCtrl.text;
                    if (pw.isNotEmpty && pw != '••••••••') {
                      await _pwStorage.save(pw);
                      if (mounted) setState(() {});
                    }
                  },
                  child: const Text('Enregistrer le mot de passe'),
                ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Section navigation fixe'),
          subtitle: const Text(
            'Épingle ↑↓←→ Esc Tab à gauche de la barre',
          ),
          value: widget.settings.fixedNavSection,
          activeColor: const Color(0xFF00FF41),
          onChanged: (v) => ref
              .read(settingsNotifierProvider.notifier)
              .save(widget.settings.copyWith(fixedNavSection: v)),
        ),
        ListTile(
          title: const Text('Réinitialiser la barre clavier'),
          subtitle: const Text('Remet les boutons par défaut'),
          trailing: const Icon(Icons.refresh, color: Colors.grey),
          onTap: () => ref
              .read(settingsNotifierProvider.notifier)
              .save(widget.settings.copyWith(toolbarButtons: [])),
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
