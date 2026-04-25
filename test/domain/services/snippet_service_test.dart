import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/domain/services/snippet_service.dart';

void main() {
  group('SnippetService.extractVariables', () {
    test('template sans variable retourne liste vide', () {
      expect(SnippetService.extractVariables('df -h'), isEmpty);
    });

    test('extrait une variable', () {
      expect(
        SnippetService.extractVariables('tail -n {lines} /var/log/syslog'),
        ['lines'],
      );
    });

    test('extrait plusieurs variables dans l ordre', () {
      final vars = SnippetService.extractVariables(
        'tail -n {lines} /var/log/{service}.log',
      );
      expect(vars, containsAll(['lines', 'service']));
      expect(vars.length, 2);
    });

    test('déduplique les variables identiques', () {
      expect(SnippetService.extractVariables('{a} {a}'), ['a']);
    });
  });

  group('SnippetService.resolve', () {
    test('résout un template simple', () {
      final r = SnippetService.resolve('tail -n {lines}', {'lines': '100'});
      expect(r.isOk, isTrue);
      expect(r.value, 'tail -n 100');
    });

    test('retourne Err si variable manquante', () {
      final r = SnippetService.resolve('tail -n {lines}', {});
      expect(r.isErr, isTrue);
      expect(r.error, contains('lines'));
    });

    test('template sans variable ignoré si map non vide', () {
      final r = SnippetService.resolve('df -h', {'unused': 'x'});
      expect(r.isOk, isTrue);
      expect(r.value, 'df -h');
    });
  });
}
