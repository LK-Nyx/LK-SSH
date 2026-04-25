import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/core/secure_key.dart';
import 'package:lk_ssh/data/models/server.dart';
import 'package:lk_ssh/domain/services/ssh_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSshClientFactory extends Mock implements SshClientFactory {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Server(id: '', label: '', host: '', port: 22, username: ''),
    );
    registerFallbackValue(Uint8List(0));
  });

  group('SSHService', () {
    test('connect retourne SshConnectionError si la factory échoue', () async {
      final factory = MockSshClientFactory();
      final service = SSHService(factory);
      final server = Server(
        id: '1',
        label: 'test',
        host: '127.0.0.1',
        port: 22,
        username: 'root',
      );
      final key = SecureKey.fromBytes(Uint8List.fromList([1, 2, 3]));

      when(
        () => factory.connect(
          server: any(named: 'server'),
          keyBytes: any(named: 'keyBytes'),
        ),
      ).thenThrow(Exception('Connection refused'));

      final result = await service.connect(server: server, privateKey: key);
      expect(result.isErr, isTrue);
      expect(result.error, isA<SshConnectionError>());
      expect(key.isDisposed, isTrue);
    });
  });
}
