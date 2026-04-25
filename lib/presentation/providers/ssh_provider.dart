import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import '../../data/models/server.dart';
import '../../data/models/session.dart';
import '../../domain/services/ssh_service.dart';
import 'sessions_provider.dart';

part 'ssh_provider.g.dart';

@riverpod
class SshNotifier extends _$SshNotifier {
  SshConnection? _connection;

  @override
  AsyncValue<SshConnection?> build(String sessionId) {
    ref.onDispose(() => _connection?.close());
    return const AsyncData(null);
  }

  Future<Result<SshConnection, AppError>> connect(
    Server server,
    SecureKey key,
  ) async {
    state = const AsyncLoading();
    final service = SSHService();
    final result = await service.connect(server: server, privateKey: key);
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

  void disconnect() {
    _connection?.close();
    _connection = null;
    state = const AsyncData(null);
    ref
        .read(sessionsNotifierProvider.notifier)
        .updateStatus(sessionId, SessionStatus.disconnected);
  }

}
