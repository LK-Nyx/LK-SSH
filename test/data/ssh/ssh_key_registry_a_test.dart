import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/core/result.dart';
import 'package:lk_ssh/data/ssh/ssh_key_registry_a.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecure extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecure secure;
  late SshKeyRegistryA registry;

  setUp(() {
    secure = _MockSecure();
    registry = SshKeyRegistryA.forTest(secure);
  });

  test('save writes bytes under key_<id> and passphrase under pp_<id>', () async {
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    await registry.save(keyId: 'k1', bytes: bytes, passphrase: 'secret');
    verify(() => secure.write(key: 'key_k1', value: base64Encode(bytes))).called(1);
    verify(() => secure.write(key: 'pp_k1', value: 'secret')).called(1);
  });

  test('save without passphrase still erases any previous one', () async {
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await registry.save(keyId: 'k2', bytes: Uint8List.fromList([9]));
    verify(() => secure.delete(key: 'pp_k2')).called(1);
  });

  test('loadBytes returns SecureKey when present', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => secure.read(key: 'key_k1'))
        .thenAnswer((_) async => base64Encode(bytes));
    final r = await registry.loadBytes('k1');
    switch (r) {
      case Ok(:final value):
        expect(value.bytes, bytes);
      case Err():
        fail('expected Ok');
    }
  });

  test('loadBytes returns KeyNotFoundError when absent', () async {
    when(() => secure.read(key: 'key_missing')).thenAnswer((_) async => null);
    final r = await registry.loadBytes('missing');
    switch (r) {
      case Err(:final error):
        expect(error, isA<KeyNotFoundError>());
      case Ok():
        fail('expected Err');
    }
  });

  test('loadPassphrase returns null when not stored', () async {
    when(() => secure.read(key: 'pp_k1')).thenAnswer((_) async => null);
    expect(await registry.loadPassphrase('k1'), null);
  });

  test('delete removes both key and passphrase entries', () async {
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await registry.delete('k1');
    verify(() => secure.delete(key: 'key_k1')).called(1);
    verify(() => secure.delete(key: 'pp_k1')).called(1);
  });
}
