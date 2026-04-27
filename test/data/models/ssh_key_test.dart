import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/ssh_key.dart';

void main() {
  test('SshKey json round-trip', () {
    final original = SshKey(
      id: 'abc',
      label: 'MacBook perso',
      addedAt: DateTime.utc(2026, 4, 27, 10, 30),
    );
    final restored = SshKey.fromJson(original.toJson());
    expect(restored, original);
  });
}
