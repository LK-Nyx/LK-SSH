import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/secure_key.dart';

void main() {
  group('SecureKey', () {
    test('expose les bytes avant zeroise', () {
      final key = SecureKey.fromBytes(Uint8List.fromList([1, 2, 3]));
      expect(key.bytes, [1, 2, 3]);
    });

    test('bytes retourne une copie (pas de référence directe)', () {
      final key = SecureKey.fromBytes(Uint8List.fromList([1, 2, 3]));
      final copy = key.bytes;
      copy[0] = 99;
      expect(key.bytes[0], 1);
    });

    test('bytes jette StateError après zeroise', () {
      final key = SecureKey.fromBytes(Uint8List.fromList([1, 2, 3]));
      key.zeroise();
      expect(() => key.bytes, throwsStateError);
    });

    test('isDisposed est true après zeroise', () {
      final key = SecureKey.fromBytes(Uint8List.fromList([1]));
      expect(key.isDisposed, isFalse);
      key.zeroise();
      expect(key.isDisposed, isTrue);
    });
  });
}
