import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

typedef KeyEditorResult = ({String label, Uint8List bytes, String? passphrase});

class KeyEditorSheet extends StatefulWidget {
  const KeyEditorSheet({super.key});

  static Future<KeyEditorResult?> show(BuildContext context) {
    return showModalBottomSheet<KeyEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const KeyEditorSheet(),
      ),
    );
  }

  @override
  State<KeyEditorSheet> createState() => _KeyEditorSheetState();
}

class _KeyEditorSheetState extends State<KeyEditorSheet> {
  final _label = TextEditingController();
  final _pem = TextEditingController();
  final _pp = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _pem.dispose();
    _pp.dispose();
    super.dispose();
  }

  bool _tryParse() {
    try {
      SSHKeyPair.fromPem(_pem.text, _pp.text.isEmpty ? null : _pp.text);
      setState(() => _error = null);
      return true;
    } catch (_) {
      setState(() => _error = 'Clé invalide ou mauvaise passphrase.');
      return false;
    }
  }

  void _submit() {
    if (_label.text.trim().isEmpty) {
      setState(() => _error = 'Le label est requis.');
      return;
    }
    if (!_tryParse()) return;
    Navigator.pop<KeyEditorResult>(context, (
      label: _label.text.trim(),
      bytes: Uint8List.fromList(_pem.text.codeUnits),
      passphrase: _pp.text.isEmpty ? null : _pp.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouvelle clé SSH',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'MacBook perso',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pem,
            maxLines: 8,
            minLines: 4,
            decoration: const InputDecoration(
              labelText: 'Clé privée (PEM)',
              hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pp,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Passphrase (si chiffrée)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop<KeyEditorResult>(context, null),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _tryParse,
                child: const Text('Tester'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
