import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/core/result.dart';
import 'package:lk_ssh/data/ssh/ssh_key_registry_d.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lk_ssh_kd_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('save then loadBytes returns the same bytes (same passphrase)', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp1');
    final bytes = Uint8List.fromList(List.generate(64, (i) => i));
    final saveR = await reg.save(keyId: 'k1', bytes: bytes);
    expect(saveR, isA<Ok<void, AppError>>());

    final reg2 = SshKeyRegistryD(directory: tmp, passphrase: 'pp1');
    final r = await reg2.loadBytes('k1');
    switch (r) {
      case Ok(:final value):
        expect(value.bytes, bytes);
      case Err():
        fail('expected Ok');
    }
  });

  test('wrong passphrase returns KeyDecryptionError', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'good');
    await reg.save(keyId: 'k1', bytes: Uint8List.fromList([1, 2, 3]));

    final reg2 = SshKeyRegistryD(directory: tmp, passphrase: 'wrong');
    final r = await reg2.loadBytes('k1');
    switch (r) {
      case Err(:final error):
        expect(error, isA<KeyDecryptionError>());
      case Ok():
        fail('expected Err');
    }
  });

  test('multiple keys in same vault', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'a', bytes: Uint8List.fromList([1]));
    await reg.save(keyId: 'b', bytes: Uint8List.fromList([2]));
    final ra = await reg.loadBytes('a');
    final rb = await reg.loadBytes('b');
    switch (ra) {
      case Ok(:final value):
        expect(value.bytes, [1]);
      case Err():
        fail('a');
    }
    switch (rb) {
      case Ok(:final value):
        expect(value.bytes, [2]);
      case Err():
        fail('b');
    }
  });

  test('passphrase round-trip', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'k', bytes: Uint8List.fromList([0]), passphrase: 'inner-pp');
    expect(await reg.loadPassphrase('k'), 'inner-pp');
  });

  test('delete removes the entry', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'k', bytes: Uint8List.fromList([1]));
    await reg.delete('k');
    final r = await reg.loadBytes('k');
    expect(r, isA<Err<dynamic, AppError>>());
  });

  test('loadBytes on missing keyId returns KeyNotFoundError', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'k', bytes: Uint8List.fromList([1]));
    final r = await reg.loadBytes('other');
    switch (r) {
      case Err(:final error):
        expect(error, isA<KeyNotFoundError>());
      case Ok():
        fail('expected Err');
    }
  });
}
