import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/data/ssh/secure_key_storage_d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('SecureKeyStorageD', () {
    test('storeKey sans passphrase retourne KeyDecryptionError', () async {
      final s = SecureKeyStorageD();
      final r = await s.storeKey(Uint8List.fromList([1]));
      expect(r.isErr, isTrue);
      expect(r.error, isA<KeyDecryptionError>());
    });

    test('loadKey sans passphrase retourne KeyDecryptionError', () async {
      final s = SecureKeyStorageD();
      final r = await s.loadKey();
      expect(r.isErr, isTrue);
      expect(r.error, isA<KeyDecryptionError>());
    });

    test('storeKey + loadKey avec bonne passphrase roundtrip', () async {
      final s = SecureKeyStorageD();
      final bytes = Uint8List.fromList([42, 43, 44]);
      await s.storeKey(bytes, passphrase: 'secret');
      final r = await s.loadKey(passphrase: 'secret');
      expect(r.isOk, isTrue);
      expect(r.value.bytes, bytes);
    });

    test('loadKey avec mauvaise passphrase retourne KeyDecryptionError', () async {
      final s = SecureKeyStorageD();
      await s.storeKey(Uint8List.fromList([1, 2]), passphrase: 'good');
      final r = await s.loadKey(passphrase: 'bad');
      expect(r.isErr, isTrue);
      expect(r.error, isA<KeyDecryptionError>());
    });
  });
}
