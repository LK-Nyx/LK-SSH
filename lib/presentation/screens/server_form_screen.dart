import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/server.dart';
import '../providers/servers_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.server?.label ?? '');
    _hostCtrl = TextEditingController(text: widget.server?.host ?? '');
    _portCtrl =
        TextEditingController(text: '${widget.server?.port ?? 22}');
    _userCtrl =
        TextEditingController(text: widget.server?.username ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(serversNotifierProvider.notifier);
    if (widget.server == null) {
      notifier.add(newServer(
        label: _labelCtrl.text.trim(),
        host: _hostCtrl.text.trim(),
        port: int.parse(_portCtrl.text.trim()),
        username: _userCtrl.text.trim(),
      ));
    } else {
      notifier.replace(widget.server!.copyWith(
        label: _labelCtrl.text.trim(),
        host: _hostCtrl.text.trim(),
        port: int.parse(_portCtrl.text.trim()),
        username: _userCtrl.text.trim(),
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.server == null ? 'Nouveau serveur' : 'Modifier',
        ),
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
