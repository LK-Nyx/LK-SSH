import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/server.dart';
import 'storage_provider.dart';

part 'servers_provider.g.dart';

@riverpod
class ServersNotifier extends _$ServersNotifier {
  @override
  Future<List<Server>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final result = await storage.loadServers();
    return result.when(ok: (s) => s, err: (_) => []);
  }

  Future<void> add(Server server) async {
    final current = await future;
    final updated = [...current, server];
    final storage = await ref.read(storageProvider.future);
    await storage.saveServers(updated);
    state = AsyncData(updated);
  }

  Future<void> replace(Server server) async {
    final current = await future;
    final updated = current.map((s) => s.id == server.id ? server : s).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveServers(updated);
    state = AsyncData(updated);
  }

  Future<void> delete(String id) async {
    final current = await future;
    final updated = current.where((s) => s.id != id).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveServers(updated);
    state = AsyncData(updated);
  }
}

Server newServer({
  required String label,
  required String host,
  required int port,
  required String username,
}) =>
    Server(
      id: const Uuid().v4(),
      label: label,
      host: host,
      port: port,
      username: username,
    );
