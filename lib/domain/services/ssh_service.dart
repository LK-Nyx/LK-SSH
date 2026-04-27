import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/auth_credentials.dart';
import '../../data/models/server.dart';
import '../../data/storage/debug_log_service.dart';
import 'host_key_verifier.dart';

abstract interface class SshClientFactory {
  Future<SSHClient> connect({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  });
}

final class DefaultSshClientFactory implements SshClientFactory {
  static const _connectTimeout = Duration(seconds: 15);
  static const _authTimeout = Duration(seconds: 20);

  @override
  Future<SSHClient> connect({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  }) async {
    final socket = await SSHSocket.connect(server.host, server.port)
        .timeout(_connectTimeout);

    Future<bool> verifyHost(String type, Uint8List fingerprintBytes) {
      // dartssh2 hands us the MD5 digest of the host key. We base64-encode it
      // for stable string comparison and storage.
      final fp = base64.encode(fingerprintBytes);
      return Future.value(verifier.verify(
        host: server.host,
        port: server.port,
        fingerprint: fp,
      ));
    }

    final client = switch (credentials) {
      KeyCreds(:final bytes, :final passphrase) => SSHClient(
          socket,
          username: server.username,
          identities: SSHKeyPair.fromPem(
            String.fromCharCodes(bytes),
            passphrase,
          ),
          keepAliveInterval: const Duration(seconds: 30),
          onVerifyHostKey: verifyHost,
        ),
      PasswordCreds(:final password) => SSHClient(
          socket,
          username: server.username,
          onPasswordRequest: () => password,
          keepAliveInterval: const Duration(seconds: 30),
          onVerifyHostKey: verifyHost,
        ),
      InteractiveCreds(:final onPrompt) => SSHClient(
          socket,
          username: server.username,
          onUserInfoRequest: (req) => onPrompt(req),
          keepAliveInterval: const Duration(seconds: 30),
          onVerifyHostKey: verifyHost,
        ),
    };
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
    log.log('SSH',
        'openShell(width=$width, height=$height) — _activeShell avant: ${_activeShell == null ? "null" : "non-null"}');
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
    log.log('SSH',
        'sendCommand("$command") — _activeShell: ${_activeShell == null ? "NULL ← PROBLÈME" : "OK"}');
    _activeShell?.write(Uint8List.fromList(utf8.encode('$command\n')));
  }

  void sendRaw(Uint8List bytes) {
    final log = DebugLogService.instance;
    log.log('SSH',
        'sendRaw(${bytes.length} bytes) — _activeShell: ${_activeShell == null ? "NULL ← PROBLÈME" : "OK"}');
    _activeShell?.write(bytes);
  }

  void close() => client.close();
}

final class SSHService {
  SSHService([SshClientFactory? factory])
      : _factory = factory ?? DefaultSshClientFactory();

  final SshClientFactory _factory;

  Future<Result<SshConnection, AppError>> connectWith({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  }) async {
    try {
      final client = await _factory.connect(
        server: server,
        credentials: credentials,
        verifier: verifier,
      );
      return Ok(SshConnection(client: client, server: server));
    } on SSHAuthFailError catch (e) {
      return Err(SshAuthError(e.toString()));
    } on TimeoutException {
      return const Err(SshConnectionError(
          'Délai dépassé — serveur injoignable ou authentification trop lente.'));
    } catch (e) {
      return Err(SshConnectionError(e.toString()));
    }
  }
}
