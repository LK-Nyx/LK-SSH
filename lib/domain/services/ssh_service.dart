import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import '../../data/models/server.dart';

abstract interface class SshClientFactory {
  Future<SSHClient> connect({
    required Server server,
    required Uint8List keyBytes,
  });
}

final class DefaultSshClientFactory implements SshClientFactory {
  @override
  Future<SSHClient> connect({
    required Server server,
    required Uint8List keyBytes,
  }) async {
    final socket = await SSHSocket.connect(server.host, server.port);
    final client = SSHClient(
      socket,
      username: server.username,
      identities: SSHKeyPair.fromPem(String.fromCharCodes(keyBytes)),
    );
    await client.authenticated;
    return client;
  }
}

final class SshConnection {
  SshConnection({required this.client, required this.server});

  final SSHClient client;
  final Server server;

  Future<Result<SSHSession, AppError>> openShell({
    int width = 80,
    int height = 24,
  }) async {
    try {
      final shell = await client.shell(
        pty: SSHPtyConfig(width: width, height: height),
      );
      return Ok(shell);
    } catch (e) {
      return Err(SshConnectionError(e.toString()));
    }
  }

  void close() => client.close();
}

final class SSHService {
  SSHService([SshClientFactory? factory])
      : _factory = factory ?? DefaultSshClientFactory();

  final SshClientFactory _factory;

  Future<Result<SshConnection, AppError>> connect({
    required Server server,
    required SecureKey privateKey,
  }) async {
    final keyBytes = Uint8List.fromList(privateKey.bytes);
    privateKey.zeroise();
    try {
      final client = await _factory.connect(server: server, keyBytes: keyBytes);
      return Ok(SshConnection(client: client, server: server));
    } on SSHAuthFailError catch (e) {
      return Err(SshAuthError(e.toString()));
    } catch (e) {
      return Err(SshConnectionError(e.toString()));
    }
  }
}
