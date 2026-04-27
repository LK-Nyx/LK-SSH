import '../../data/models/auth_prompt_request.dart';
import '../../data/storage/i_known_hosts_storage.dart';

class HostKeyVerifier {
  HostKeyVerifier({
    required this.storage,
    required this.onMismatch,
  });

  final IKnownHostsStorage storage;
  final Future<HostKeyDecision> Function(HostKeyChange) onMismatch;

  Future<bool> verify({
    required String host,
    required int port,
    required String fingerprint,
  }) async {
    final known = await storage.load(host, port);
    if (known == null) {
      // F1a — auto-pin on first connection.
      await storage.save(host, port, fingerprint);
      return true;
    }
    if (known == fingerprint) return true;

    final decision = await onMismatch(HostKeyChange(
      host: host,
      port: port,
      oldFingerprint: known,
      newFingerprint: fingerprint,
    ));
    switch (decision) {
      case HostKeyDecision.reject:
        return false;
      case HostKeyDecision.acceptOnce:
        return true;
      case HostKeyDecision.acceptAndPin:
        await storage.save(host, port, fingerprint);
        return true;
    }
  }
}
