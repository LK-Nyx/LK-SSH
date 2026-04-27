import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/auth_prompt_request.dart';
import 'package:lk_ssh/data/storage/i_known_hosts_storage.dart';
import 'package:lk_ssh/domain/services/host_key_verifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements IKnownHostsStorage {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
  });

  test('unknown host: auto-pin and accept', () async {
    when(() => storage.load('h', 22)).thenAnswer((_) async => null);
    when(() => storage.save('h', 22, 'fp-new')).thenAnswer((_) async {});
    final v = HostKeyVerifier(
      storage: storage,
      onMismatch: (_) async => HostKeyDecision.reject,
    );
    final ok = await v.verify(host: 'h', port: 22, fingerprint: 'fp-new');
    expect(ok, true);
    verify(() => storage.save('h', 22, 'fp-new')).called(1);
  });

  test('matching fingerprint: accept without re-saving', () async {
    when(() => storage.load('h', 22)).thenAnswer((_) async => 'fp');
    final v = HostKeyVerifier(
      storage: storage,
      onMismatch: (_) async => HostKeyDecision.reject,
    );
    final ok = await v.verify(host: 'h', port: 22, fingerprint: 'fp');
    expect(ok, true);
    verifyNever(() => storage.save(any(), any(), any()));
  });

  group('mismatch', () {
    setUp(() {
      when(() => storage.load('h', 22)).thenAnswer((_) async => 'old-fp');
    });

    test('reject decision returns false, no save', () async {
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (_) async => HostKeyDecision.reject,
      );
      final ok = await v.verify(host: 'h', port: 22, fingerprint: 'new-fp');
      expect(ok, false);
      verifyNever(() => storage.save(any(), any(), any()));
    });

    test('acceptOnce returns true, no save', () async {
      when(() => storage.save(any(), any(), any())).thenAnswer((_) async {});
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (_) async => HostKeyDecision.acceptOnce,
      );
      final ok = await v.verify(host: 'h', port: 22, fingerprint: 'new-fp');
      expect(ok, true);
      verifyNever(() => storage.save(any(), any(), any()));
    });

    test('acceptAndPin returns true, saves new fp', () async {
      when(() => storage.save('h', 22, 'new-fp')).thenAnswer((_) async {});
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (_) async => HostKeyDecision.acceptAndPin,
      );
      final ok = await v.verify(host: 'h', port: 22, fingerprint: 'new-fp');
      expect(ok, true);
      verify(() => storage.save('h', 22, 'new-fp')).called(1);
    });

    test('mismatch handler receives both fingerprints', () async {
      HostKeyChange? captured;
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (change) async {
          captured = change;
          return HostKeyDecision.reject;
        },
      );
      await v.verify(host: 'h', port: 22, fingerprint: 'new-fp');
      expect(captured?.oldFingerprint, 'old-fp');
      expect(captured?.newFingerprint, 'new-fp');
    });
  });
}
