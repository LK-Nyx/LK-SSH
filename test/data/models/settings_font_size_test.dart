import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/settings.dart';

void main() {
  group('Settings.terminalFontSize', () {
    test('valeur par défaut est 14.0', () {
      expect(const Settings().terminalFontSize, 14.0);
    });

    test('sérialise et relit correctement', () {
      const s = Settings(terminalFontSize: 20.0);
      final json = s.toJson();
      final restored = Settings.fromJson(json);
      expect(restored.terminalFontSize, 20.0);
    });

    test('fromJson sans la clé retourne 14.0', () {
      final json = const Settings().toJson()..remove('terminalFontSize');
      final restored = Settings.fromJson(json);
      expect(restored.terminalFontSize, 14.0);
    });
  });
}
