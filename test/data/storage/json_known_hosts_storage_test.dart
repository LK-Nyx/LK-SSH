import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/storage/json_known_hosts_storage.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lk_ssh_kh_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('save then load returns the fingerprint', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('example.com', 22, 'SHA256:abc');
    expect(await storage.load('example.com', 22), 'SHA256:abc');
  });

  test('load returns null when host:port is unknown', () async {
    final storage = JsonKnownHostsStorage(tmp);
    expect(await storage.load('unknown.com', 22), null);
  });

  test('save overwrites a previous fingerprint', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('h.com', 22, 'SHA256:old');
    await storage.save('h.com', 22, 'SHA256:new');
    expect(await storage.load('h.com', 22), 'SHA256:new');
  });

  test('delete removes the entry', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('h.com', 22, 'SHA256:abc');
    await storage.delete('h.com', 22);
    expect(await storage.load('h.com', 22), null);
  });

  test('host:port distinguishes entries', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('h.com', 22, 'A');
    await storage.save('h.com', 2222, 'B');
    expect(await storage.load('h.com', 22), 'A');
    expect(await storage.load('h.com', 2222), 'B');
  });
}
