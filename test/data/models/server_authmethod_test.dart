import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/auth_method.dart';
import 'package:lk_ssh/data/models/server.dart';

void main() {
  group('Server with auth fields', () {
    test('default authMethod is key, keyId null, savePassword false', () {
      const s = Server(id: 'x', label: 'x', host: 'h', username: 'u');
      expect(s.authMethod, AuthMethod.key);
      expect(s.keyId, null);
      expect(s.savePassword, false);
    });

    test('json round-trip preserves new fields', () {
      const original = Server(
        id: 'x',
        label: 'x',
        host: 'h',
        username: 'u',
        authMethod: AuthMethod.password,
        keyId: 'k1',
        savePassword: true,
      );
      final restored = Server.fromJson(original.toJson());
      expect(restored, original);
    });

    test('json round-trip on a v1-style payload uses defaults', () {
      final v1Json = {
        'id': 'x',
        'label': 'x',
        'host': 'h',
        'port': 22,
        'username': 'u',
      };
      final restored = Server.fromJson(v1Json);
      expect(restored.authMethod, AuthMethod.key);
      expect(restored.keyId, null);
      expect(restored.savePassword, false);
    });
  });
}
