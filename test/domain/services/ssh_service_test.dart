import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/data/models/auth_credentials.dart';
import 'package:lk_ssh/data/models/server.dart';
import 'package:lk_ssh/data/storage/i_known_hosts_storage.dart';
import 'package:lk_ssh/domain/services/host_key_verifier.dart';
import 'package:lk_ssh/domain/services/ssh_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSshClientFactory extends Mock implements SshClientFactory {}

class _MockKnownHosts extends Mock implements IKnownHostsStorage {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Server(id: '', label: '', host: '', port: 22, username: ''),
    );
    registerFallbackValue(KeyCreds(bytes: Uint8List(0)));
    registerFallbackValue(HostKeyVerifier(
      storage: _MockKnownHosts(),
      onMismatch: (_) async => throw UnimplementedError(),
    ));
  });

  group('SSHService', () {
    test('connectWith retourne SshConnectionError si la factory échoue', () async {
      final factory = MockSshClientFactory();
      final service = SSHService(factory);
      const server = Server(
        id: '1',
        label: 'test',
        host: '127.0.0.1',
        port: 22,
        username: 'root',
      );
      final verifier = HostKeyVerifier(
        storage: _MockKnownHosts(),
        onMismatch: (_) async => throw UnimplementedError(),
      );

      when(
        () => factory.connect(
          server: any(named: 'server'),
          credentials: any(named: 'credentials'),
          verifier: any(named: 'verifier'),
        ),
      ).thenThrow(Exception('Connection refused'));

      final result = await service.connectWith(
        server: server,
        credentials: KeyCreds(bytes: Uint8List.fromList([1, 2, 3])),
        verifier: verifier,
      );
      expect(result.isErr, isTrue);
      expect(result.error, isA<SshConnectionError>());
    });
  });
}
