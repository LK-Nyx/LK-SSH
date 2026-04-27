import 'dart:convert';
import 'dart:io';

import 'i_known_hosts_storage.dart';

final class JsonKnownHostsStorage implements IKnownHostsStorage {
  JsonKnownHostsStorage(this._directory);

  final Directory _directory;

  File get _file => File('${_directory.path}/known_hosts.json');

  String _key(String host, int port) => '$host:$port';

  Future<Map<String, String>> _read() async {
    if (!await _file.exists()) return {};
    try {
      final raw = await _file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, String> data) async {
    await _file.writeAsString(jsonEncode(data));
  }

  @override
  Future<String?> load(String host, int port) async =>
      (await _read())[_key(host, port)];

  @override
  Future<void> save(String host, int port, String fingerprint) async {
    final data = await _read();
    data[_key(host, port)] = fingerprint;
    await _write(data);
  }

  @override
  Future<void> delete(String host, int port) async {
    final data = await _read();
    data.remove(_key(host, port));
    await _write(data);
  }
}
