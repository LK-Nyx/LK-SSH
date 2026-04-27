import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../data/models/auth_method.dart';
import '../../data/models/server.dart';
import '../providers/password_storage_provider.dart';
import '../providers/servers_provider.dart';
import '../providers/ssh_keys_provider.dart';
import '../widgets/key_editor_sheet.dart';

class ServerFormScreen extends ConsumerStatefulWidget {
  const ServerFormScreen({super.key, this.server});
  final Server? server;

  @override
  ConsumerState<ServerFormScreen> createState() => _ServerFormScreenState();
}

class _ServerFormScreenState extends ConsumerState<ServerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passwordCtrl;
  late AuthMethod _authMethod;
  String? _keyId;
  late bool _savePassword;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.server?.label ?? '');
    _hostCtrl = TextEditingController(text: widget.server?.host ?? '');
    _portCtrl = TextEditingController(text: '${widget.server?.port ?? 22}');
    _userCtrl = TextEditingController(text: widget.server?.username ?? '');
    _passwordCtrl = TextEditingController();
    _authMethod = widget.server?.authMethod ?? AuthMethod.key;
    _keyId = widget.server?.keyId;
    _savePassword = widget.server?.savePassword ?? false;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_authMethod == AuthMethod.key && _keyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une clé.')),
      );
      return;
    }
    if (_authMethod == AuthMethod.password && _passwordCtrl.text.isEmpty &&
        widget.server == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe requis.')),
      );
      return;
    }

    final notifier = ref.read(serversNotifierProvider.notifier);
    final pwdStorage = ref.read(passwordStorageProvider);

    final isNew = widget.server == null;
    final base = isNew
        ? newServer(
            label: _labelCtrl.text.trim(),
            host: _hostCtrl.text.trim(),
            port: int.parse(_portCtrl.text.trim()),
            username: _userCtrl.text.trim(),
          )
        : widget.server!;

    final updated = base.copyWith(
      label: _labelCtrl.text.trim(),
      host: _hostCtrl.text.trim(),
      port: int.parse(_portCtrl.text.trim()),
      username: _userCtrl.text.trim(),
      authMethod: _authMethod,
      keyId: _authMethod == AuthMethod.key ? _keyId : null,
      savePassword: _authMethod == AuthMethod.password ? _savePassword : false,
    );

    if (isNew) {
      notifier.add(updated);
    } else {
      notifier.replace(updated);
    }

    if (_authMethod == AuthMethod.password) {
      if (_savePassword && _passwordCtrl.text.isNotEmpty) {
        await pwdStorage.save(updated.id, _passwordCtrl.text);
      } else if (!_savePassword) {
        await pwdStorage.delete(updated.id);
      }
    } else {
      await pwdStorage.delete(updated.id);
    }

    if (mounted) Navigator.pop(context);
  }

  Widget _buildKeyPicker() {
    final keysAsync = ref.watch(sshKeysNotifierProvider);
    return keysAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Erreur: $e'),
      data: (keys) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: keys.any((k) => k.id == _keyId) ? _keyId : null,
            decoration: const InputDecoration(
              labelText: 'Clé',
              border: OutlineInputBorder(),
            ),
            hint: Text(keys.isEmpty
                ? 'Aucune clé enregistrée — ajoutez-en une'
                : 'Choisir une clé'),
            items: [
              for (final k in keys)
                DropdownMenuItem(value: k.id, child: Text(k.label)),
            ],
            onChanged:
                keys.isEmpty ? null : (v) => setState(() => _keyId = v),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle clé'),
            onPressed: () async {
              final result = await KeyEditorSheet.show(context);
              if (result == null) return;
              final added =
                  await ref.read(sshKeysNotifierProvider.notifier).add(
                        label: result.label,
                        bytes: result.bytes,
                        passphrase: result.passphrase,
                      );
              switch (added) {
                case Ok(:final value):
                  setState(() => _keyId = value.id);
                case Err():
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            hintText: widget.server != null && widget.server!.savePassword
                ? '(déjà enregistré — laisser vide pour conserver)'
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _passwordCtrl,
          builder: (_, value, __) => value.text.isEmpty
              ? const SizedBox.shrink()
              : CheckboxListTile(
                  value: _savePassword,
                  onChanged: (v) => setState(() => _savePassword = v ?? false),
                  title: const Text('Se souvenir'),
                  contentPadding: EdgeInsets.zero,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server == null ? 'Nouveau serveur' : 'Modifier'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Field(
              controller: _labelCtrl,
              label: 'Label',
              hint: 'prod-server-01',
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _hostCtrl,
              label: 'Host / IP',
              hint: '192.168.1.10',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _portCtrl,
              label: 'Port',
              hint: '22',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1 || n > 65535)
                    ? 'Port invalide'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _userCtrl,
              label: 'Utilisateur',
              hint: 'root',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 24),
            const Text('Authentification',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<AuthMethod>(
              value: _authMethod,
              decoration: const InputDecoration(
                labelText: 'Méthode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: AuthMethod.key, child: Text('Clé SSH')),
                DropdownMenuItem(
                    value: AuthMethod.password, child: Text('Mot de passe')),
                DropdownMenuItem(
                    value: AuthMethod.keyboardInteractive,
                    child: Text('Keyboard-interactive')),
              ],
              onChanged: (v) => setState(() => _authMethod = v ?? AuthMethod.key),
            ),
            const SizedBox(height: 12),
            if (_authMethod == AuthMethod.key) _buildKeyPicker(),
            if (_authMethod == AuthMethod.password) _buildPasswordFields(),
            if (_authMethod == AuthMethod.keyboardInteractive)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Les questions du serveur s'afficheront à la connexion.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      );
}
