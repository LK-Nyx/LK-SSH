import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/snippet.dart';
import '../providers/snippets_provider.dart';

class SnippetEditorScreen extends ConsumerStatefulWidget {
  const SnippetEditorScreen({super.key, this.snippet, this.defaultCategoryId});
  final Snippet? snippet;
  final String? defaultCategoryId;

  @override
  ConsumerState<SnippetEditorScreen> createState() =>
      _SnippetEditorScreenState();
}

class _SnippetEditorScreenState extends ConsumerState<SnippetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _commandCtrl;
  late String _categoryId;
  late bool _requireConfirm;
  late bool _autoExecute;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.snippet?.label ?? '');
    _commandCtrl = TextEditingController(text: widget.snippet?.command ?? '');
    _requireConfirm = widget.snippet?.requireConfirm ?? false;
    _autoExecute = widget.snippet?.autoExecute ?? true;
    _categoryId = widget.snippet?.categoryId ??
        widget.defaultCategoryId ??
        'system';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _commandCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(snippetsNotifierProvider.notifier);
    if (widget.snippet == null) {
      notifier.add(newSnippet(
        label: _labelCtrl.text.trim(),
        command: _commandCtrl.text.trim(),
        categoryId: _categoryId,
        requireConfirm: _requireConfirm,
        autoExecute: _autoExecute,
      ));
    } else {
      notifier.replace(widget.snippet!.copyWith(
        label: _labelCtrl.text.trim(),
        command: _commandCtrl.text.trim(),
        categoryId: _categoryId,
        requireConfirm: _requireConfirm,
        autoExecute: _autoExecute,
      ));
    }
    Navigator.pop(context);
  }

  void _applyPreset(_SnippetPreset preset) {
    setState(() {
      _labelCtrl.text = preset.label;
      _commandCtrl.text = preset.command;
      _autoExecute = preset.autoExecute;
    });
    Navigator.pop(context);
  }

  void _showPresetsSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Modèles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            for (final preset in _kPresets)
              ListTile(
                leading: Icon(preset.icon, color: preset.color, size: 22),
                title: Text(preset.title),
                subtitle: Text(
                  preset.command,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _applyPreset(preset),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.snippet == null ? 'Nouveau snippet' : 'Éditer snippet',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Modèles',
            onPressed: _showPresetsSheet,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'restart nginx',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commandCtrl,
              decoration: const InputDecoration(
                labelText: 'Commande',
                hintText: 'sudo systemctl restart nginx',
                border: OutlineInputBorder(),
                helperText: 'Utilisez {variable} pour les variables',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v!),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              title: const Text('Exécuter automatiquement'),
              subtitle: const Text('Envoie la commande avec ↵'),
              value: _autoExecute,
              activeColor: const Color(0xFF00FF41),
              onChanged: (v) => setState(() => _autoExecute = v),
            ),
            SwitchListTile(
              title: const Text('Double confirmation'),
              subtitle: const Text('Demande confirmation avant envoi'),
              value: _requireConfirm,
              activeColor: Colors.orange,
              onChanged: (v) => setState(() => _requireConfirm = v),
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

class _SnippetPreset {
  const _SnippetPreset({
    required this.icon,
    required this.color,
    required this.title,
    required this.label,
    required this.command,
    required this.autoExecute,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String label;
  final String command;
  final bool autoExecute;
}

// wayland-1 et /run/user/1000 sont les valeurs de ce système Niri.
// XDG_RUNTIME_DIR est requis pour que les apps trouvent le socket Wayland.
const _kPresets = [
  _SnippetPreset(
    icon: Icons.launch,
    color: Color(0xFF00FF41),
    title: 'Lancer une application (Wayland)',
    label: '{application}',
    command: 'WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 {application} &',
    autoExecute: true,
  ),
  _SnippetPreset(
    icon: Icons.launch,
    color: Colors.blue,
    title: 'Lancer une application (XWayland)',
    label: '{application}',
    command: 'DISPLAY=:1 {application} &',
    autoExecute: true,
  ),
  _SnippetPreset(
    icon: Icons.terminal,
    color: Colors.amber,
    title: 'Rejoindre une session tmux',
    label: 'tmux {session}',
    command: 'tmux attach -t {session}',
    autoExecute: true,
  ),
  _SnippetPreset(
    icon: Icons.add_box_outlined,
    color: Colors.amber,
    title: 'Nouvelle session tmux',
    label: 'tmux new {session}',
    command: 'tmux new-session -A -s {session}',
    autoExecute: true,
  ),
  _SnippetPreset(
    icon: Icons.list,
    color: Colors.grey,
    title: 'Lister les sessions tmux',
    label: 'tmux ls',
    command: 'tmux ls',
    autoExecute: true,
  ),
];
