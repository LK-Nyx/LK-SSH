import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/server.dart';
import '../providers/servers_provider.dart';
import '../providers/sessions_provider.dart';
import 'server_form_screen.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';

class ServerListScreen extends ConsumerWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serversNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LK-SSH',
          style: TextStyle(fontFamily: 'monospace', letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ServerFormScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: serversAsync.when(
        data: (servers) => servers.isEmpty
            ? const Center(
                child: Text(
                  'Aucun serveur\nAppuyez sur + pour en ajouter',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.separated(
                itemCount: servers.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFF2A2A2A)),
                itemBuilder: (context, i) {
                  final s = servers[i];
                  return ListTile(
                    leading: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF00FF41),
                    ),
                    title: Text(
                      s.label,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: Text(
                      '${s.host}:${s.port} · ${s.username}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      final sessionId = ref
                          .read(sessionsNotifierProvider.notifier)
                          .open(s.id, s.label);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => TerminalScreen(
                            initialSessionId: sessionId,
                            initialServer: s,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showServerMenu(context, ref, s),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  void _showServerMenu(BuildContext context, WidgetRef ref, Server server) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ServerFormScreen(server: server),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(serversNotifierProvider.notifier).delete(server.id);
            },
          ),
        ],
      ),
    );
  }
}
