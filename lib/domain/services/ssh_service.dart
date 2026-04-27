import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import '../../data/models/server.dart';
import '../../data/storage/debug_log_service.dart';

abstract interface class SshClientFactory {
  Future<SSHClient> connect({
    required Server server,
    required Uint8List keyBytes,
  });
}

final class DefaultSshClientFactory implements SshClientFactory {
  static const _connectTimeout = Duration(seconds: 15);
  static const _authTimeout = Duration(seconds: 20);

  @override
  Future<SSHClient> connect({
    required Server server,
    required Uint8List keyBytes,
  }) async {
    final socket = await SSHSocket.connect(server.host, server.port)
        .timeout(_connectTimeout);
    final client = SSHClient(
      socket,
      username: server.username,
      identities: SSHKeyPair.fromPem(String.fromCharCodes(keyBytes)),
      keepAliveInterval: const Duration(seconds: 30),
    );
    await client.authenticated.timeout(_authTimeout);
    return client;
  }
}

final class SshConnection {
  SshConnection({required this.client, required this.server});

  final SSHClient client;
  final Server server;
  SSHSession? _activeShell;

  Future<Result<SSHSession, AppError>> openShell({
    int width = 80,
    int height = 24,
  }) async {
    final log = DebugLogService.instance;
    log.log('SSH', 'openShell(width=$width, height=$height) — _activeShell avant: ${_activeShell == null ? "null" : "non-null"}');
    try {
      final shell = await client.shell(
        pty: SSHPtyConfig(width: width, height: height),
      );
      _activeShell = shell;
      log.log('SSH', 'openShell OK — _activeShell défini');
      return Ok(shell);
    } catch (e) {
      log.log('SSH', 'openShell ERREUR: $e');
      return Err(SshConnectionError(e.toString()));
    }
  }

  void sendCommand(String command) {
    final log = DebugLogService.instance;
    log.log('SSH', 'sendCommand("$command") — _activeShell: ${_activeShell == null ? "NULL ← PROBLÈME" : "OK"}');
    _activeShell?.write(Uint8List.fromList(utf8.encode('$command\n')));
  }

  void sendRaw(Uint8List bytes) {
    final log = DebugLogService.instance;
    log.log('SSH', 'sendRaw(${bytes.length} bytes: ${bytes.take(8).toList()}) — _activeShell: ${_activeShell == null ? "NULL ← PROBLÈME" : "OK"}');
    _activeShell?.write(bytes);
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
    } on TimeoutException {
      return const Err(SshConnectionError('Délai dépassé — serveur injoignable ou authentification trop lente.'));
    } catch (e) {
      return Err(SshConnectionError(e.toString()));
    }
  }
}
