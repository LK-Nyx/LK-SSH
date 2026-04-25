import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/result.dart';

void main() {
  group('Result', () {
    test('Ok.isOk est true', () {
      const r = Ok<int, String>(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.value, 42);
    });

    test('Err.isErr est true', () {
      const r = Err<int, String>('fail');
      expect(r.isErr, isTrue);
      expect(r.isOk, isFalse);
      expect(r.error, 'fail');
    });

    test('when dispatche correctement', () {
      const ok = Ok<int, String>(1);
      final result = ok.when(ok: (v) => 'ok:$v', err: (e) => 'err:$e');
      expect(result, 'ok:1');
    });
  });
}
