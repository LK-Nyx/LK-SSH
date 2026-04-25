import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/data/ssh/secure_key_storage_a.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('SecureKeyStorageA', () {
    test('hasKey retourne false si aucune clé', () async {
      final storage = SecureKeyStorageA();
      expect(await storage.hasKey(), isFalse);
    });

    test('storeKey puis loadKey roundtrip', () async {
      final storage = SecureKeyStorageA();
      final bytes = Uint8List.fromList([10, 20, 30]);
      final storeResult = await storage.storeKey(bytes);
      expect(storeResult.isOk, isTrue);

      final loadResult = await storage.loadKey();
      expect(loadResult.isOk, isTrue);
      expect(loadResult.value.bytes, bytes);
    });

    test('hasKey retourne true après storeKey', () async {
      final storage = SecureKeyStorageA();
      await storage.storeKey(Uint8List.fromList([1, 2]));
      expect(await storage.hasKey(), isTrue);
    });

    test('deleteKey supprime la clé', () async {
      final storage = SecureKeyStorageA();
      await storage.storeKey(Uint8List.fromList([1]));
      await storage.deleteKey();
      expect(await storage.hasKey(), isFalse);
    });

    test('loadKey retourne KeyNotFoundError si absente', () async {
      final storage = SecureKeyStorageA();
      final result = await storage.loadKey();
      expect(result.isErr, isTrue);
      expect(result.error, isA<KeyNotFoundError>());
    });
  });
}
