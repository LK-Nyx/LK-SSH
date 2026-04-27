import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/storage/secure_password_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecure extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecure secure;
  late SecurePasswordStorage storage;

  setUp(() {
    secure = _MockSecure();
    storage = SecurePasswordStorage.forTest(secure);
  });

  test('save writes under namespaced key', () async {
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    await storage.save('srv1', 'p4ss');
    verify(() => secure.write(key: 'pwd_srv1', value: 'p4ss')).called(1);
  });

  test('load returns the stored value', () async {
    when(() => secure.read(key: 'pwd_srv1')).thenAnswer((_) async => 'p4ss');
    expect(await storage.load('srv1'), 'p4ss');
  });

  test('load returns null when missing', () async {
    when(() => secure.read(key: 'pwd_missing')).thenAnswer((_) async => null);
    expect(await storage.load('missing'), null);
  });

  test('delete removes the stored value', () async {
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await storage.delete('srv1');
    verify(() => secure.delete(key: 'pwd_srv1')).called(1);
  });
}
