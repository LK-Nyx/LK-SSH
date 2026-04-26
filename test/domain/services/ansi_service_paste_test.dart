import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/toolbar_button.dart';
import 'package:lk_ssh/domain/services/ansi_service.dart';

void main() {
  group('AnsiService paste', () {
    test('sequenceFor(paste) retourne Uint8List vide', () {
      expect(AnsiService.sequenceFor(ToolbarButtonType.paste), isEmpty);
    });
  });

  group('defaultToolbarButtons avec paste', () {
    test("paste n'est pas dans les boutons par défaut", () {
      final types = defaultToolbarButtons().map((b) => b.type).toList();
      expect(types, isNot(contains(ToolbarButtonType.paste)));
    });

    test('defaultToolbarButtons contient toujours 27 boutons', () {
      expect(defaultToolbarButtons().length, 27);
    });
  });
}
