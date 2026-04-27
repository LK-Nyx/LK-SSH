import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/auth_credentials.dart';
import '../../data/models/auth_method.dart';
import '../../data/models/auth_prompt_request.dart';
import '../../data/models/server.dart';
import '../../data/models/session.dart';
import '../../domain/services/host_key_verifier.dart';
import '../../domain/services/ssh_service.dart';
import 'known_hosts_provider.dart';
import 'password_storage_provider.dart';
import 'sessions_provider.dart';
import 'ssh_keys_provider.dart';

part 'ssh_provider.g.dart';

@riverpod
class SshNotifier extends _$SshNotifier {
  SshConnection? _connection;
  final _prompts = StreamController<AuthPromptRequest>.broadcast();
  final _pending = <AuthPromptRequest>{};

  Stream<AuthPromptRequest> get prompts => _prompts.stream;

  @override
  AsyncValue<SshConnection?> build(String sessionId) {
    ref.onDispose(() {
      // Settle any prompt awaiting a UI response so the connect Future doesn't hang.
      for (final p in _pending) {
        switch (p) {
          case PasswordPromptRequest(:final completer):
            if (!completer.isCompleted) completer.complete(null);
          case KbInteractivePromptRequest(:final completer):
            if (!completer.isCompleted) completer.complete(null);
          case HostKeyMismatchRequest(:final completer):
            if (!completer.isCompleted) completer.complete(HostKeyDecision.reject);
        }
      }
      _pending.clear();
      _connection?.close();
      _prompts.close();
    });
    return const AsyncData(null);
  }

  void _emit(AuthPromptRequest req) {
    _pending.add(req);
    _prompts.add(req);
  }

  Future<Result<SshConnection, AppError>> connect(Server server) async {
    state = const AsyncLoading();

    final credsResult = await _resolveCredentials(server);
    final AuthCredentials credentials;
    switch (credsResult) {
      case Err(:final error):
        state = const AsyncData(null);
        ref
            .read(sessionsNotifierProvider.notifier)
            .updateStatus(sessionId, SessionStatus.error);
        return Err(error);
      case Ok(:final value):
        credentials = value;
    }

    final knownHosts = await ref.read(knownHostsStorageProvider.future);
    final verifier = HostKeyVerifier(
      storage: knownHosts,
      onMismatch: (change) async {
        final req = HostKeyMismatchRequest(change);
        _emit(req);
        final decision = await req.completer.future;
        _pending.remove(req);
        return decision;
      },
    );

    final svc = SSHService();
    final result = await svc.connectWith(
      server: server,
      credentials: credentials,
      verifier: verifier,
    );
    result.when(
      ok: (conn) {
        _connection = conn;
        state = AsyncData(conn);
        ref
            .read(sessionsNotifierProvider.notifier)
            .updateStatus(sessionId, SessionStatus.connected);
      },
      err: (_) {
        state = const AsyncData(null);
        ref
            .read(sessionsNotifierProvider.notifier)
            .updateStatus(sessionId, SessionStatus.error);
      },
    );
    return result;
  }

  Future<Result<AuthCredentials, AppError>> _resolveCredentials(Server server) async {
    switch (server.authMethod) {
      case AuthMethod.key:
        if (server.keyId == null) {
          return const Err(KeyNotFoundError());
        }
        final registry = await ref.read(sshKeyRegistryProvider.future);
        final bytesR = await registry.loadBytes(server.keyId!);
        switch (bytesR) {
          case Err(:final error):
            return Err(error);
          case Ok(:final value):
            final passphrase = await registry.loadPassphrase(server.keyId!);
            return Ok(KeyCreds(
              bytes: Uint8List.fromList(value.bytes),
              passphrase: passphrase,
            ));
        }
      case AuthMethod.password:
        String? password;
        if (server.savePassword) {
          password = await ref.read(passwordStorageProvider).load(server.id);
        }
        password ??= await _promptPassword(server);
        if (password == null) {
          return const Err(SshAuthError("Connexion annulée par l'utilisateur."));
        }
        return Ok(PasswordCreds(password));
      case AuthMethod.keyboardInteractive:
        return Ok(InteractiveCreds((req) async {
          final pr = KbInteractivePromptRequest(req);
          _emit(pr);
          final answers = await pr.completer.future;
          _pending.remove(pr);
          return answers;
        }));
    }
  }

  Future<String?> _promptPassword(Server server) async {
    final pr = PasswordPromptRequest(user: server.username, host: server.host);
    _emit(pr);
    final pp = await pr.completer.future;
    _pending.remove(pr);
    return pp;
  }

  void disconnect() {
    _connection?.close();
    _connection = null;
    state = const AsyncData(null);
    ref
        .read(sessionsNotifierProvider.notifier)
        .updateStatus(sessionId, SessionStatus.disconnected);
  }
}
