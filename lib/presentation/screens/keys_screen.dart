import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ssh_key.dart';
import '../providers/servers_provider.dart';
import '../providers/ssh_keys_provider.dart';
import '../widgets/key_editor_sheet.dart';

class KeysScreen extends ConsumerWidget {
  const KeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(sshKeysNotifierProvider);
    final servers = ref.watch(serversNotifierProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Clés SSH')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await KeyEditorSheet.show(context);
          if (result == null) return;
          await ref.read(sshKeysNotifierProvider.notifier).add(
                label: result.label,
                bytes: result.bytes,
                passphrase: result.passphrase,
              );
        },
        child: const Icon(Icons.add),
      ),
      body: keysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (keys) {
          if (keys.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucune clé enregistrée.\nAppuyez sur + pour en ajouter une.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: keys.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final k = keys[i];
              final usedBy = servers.where((s) => s.keyId == k.id).length;
              return ListTile(
                title: Text(k.label),
                subtitle: Text(
                  'Ajoutée le ${k.addedAt.toLocal().toString().split('.').first} · '
                  'utilisée par $usedBy serveur${usedBy > 1 ? 's' : ''}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'rename') {
                      await _rename(context, ref, k);
                    } else if (v == 'delete') {
                      await _confirmAndDelete(context, ref, k, usedBy);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renommer')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, SshKey k) async {
    final ctrl = TextEditingController(text: k.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renommer la clé'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (newLabel != null && newLabel.trim().isNotEmpty) {
      await ref
          .read(sshKeysNotifierProvider.notifier)
          .rename(k.id, newLabel.trim());
    }
  }

  Future<void> _confirmAndDelete(
      BuildContext context, WidgetRef ref, SshKey k, int usedBy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la clé ?'),
        content: Text(
          usedBy == 0
              ? "Cette clé n'est utilisée par aucun serveur."
              : 'Cette clé est utilisée par $usedBy serveur${usedBy > 1 ? 's' : ''}. '
                  'Ces serveurs ne pourront plus se connecter sans réassignation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sshKeysNotifierProvider.notifier).remove(k.id);
    }
  }
}
