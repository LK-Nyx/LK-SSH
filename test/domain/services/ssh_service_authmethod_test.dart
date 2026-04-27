import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/auth_credentials.dart';
import 'package:lk_ssh/data/models/server.dart';
import 'package:lk_ssh/data/storage/i_known_hosts_storage.dart';
import 'package:lk_ssh/domain/services/host_key_verifier.dart';
import 'package:lk_ssh/domain/services/ssh_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements SSHClient {}

class _MockKnownHosts extends Mock implements IKnownHostsStorage {}

class _RecordingFactory implements SshClientFactory {
  AuthCredentials? capturedCreds;
  HostKeyVerifier? capturedVerifier;

  @override
  Future<SSHClient> connect({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  }) async {
    capturedCreds = credentials;
    capturedVerifier = verifier;
    final c = _MockClient();
    when(() => c.authenticated).thenAnswer((_) async {});
    return c;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  test('connectWith dispatches with PasswordCreds', () async {
    final factory = _RecordingFactory();
    final svc = SSHService(factory);
    final verifier = HostKeyVerifier(
      storage: _MockKnownHosts(),
      onMismatch: (_) async => throw UnimplementedError(),
    );
    final r = await svc.connectWith(
      server: const Server(id: 's', label: 's', host: 'h', username: 'u'),
      credentials: const PasswordCreds('hunter2'),
      verifier: verifier,
    );
    expect(r.isOk, true);
    expect(factory.capturedCreds, isA<PasswordCreds>());
    expect(factory.capturedVerifier, verifier);
  });

  test('connectWith dispatches with KeyCreds', () async {
    final factory = _RecordingFactory();
    final svc = SSHService(factory);
    final verifier = HostKeyVerifier(
      storage: _MockKnownHosts(),
      onMismatch: (_) async => throw UnimplementedError(),
    );
    final bytes = Uint8List.fromList([1, 2, 3]);
    final r = await svc.connectWith(
      server: const Server(id: 's', label: 's', host: 'h', username: 'u'),
      credentials: KeyCreds(bytes: bytes, passphrase: 'pp'),
      verifier: verifier,
    );
    expect(r.isOk, true);
    expect(factory.capturedCreds, isA<KeyCreds>());
    final captured = factory.capturedCreds as KeyCreds;
    expect(captured.bytes, bytes);
    expect(captured.passphrase, 'pp');
  });

  test('connectWith dispatches with InteractiveCreds', () async {
    final factory = _RecordingFactory();
    final svc = SSHService(factory);
    final verifier = HostKeyVerifier(
      storage: _MockKnownHosts(),
      onMismatch: (_) async => throw UnimplementedError(),
    );
    final r = await svc.connectWith(
      server: const Server(id: 's', label: 's', host: 'h', username: 'u'),
      credentials: InteractiveCreds((_) async => <String>[]),
      verifier: verifier,
    );
    expect(r.isOk, true);
    expect(factory.capturedCreds, isA<InteractiveCreds>());
  });
}
