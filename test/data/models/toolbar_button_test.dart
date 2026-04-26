import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/toolbar_button.dart';

void main() {
  group('ToolbarButton', () {
    test('sérialise vers JSON et relit correctement', () {
      const btn = ToolbarButton(type: ToolbarButtonType.ctrl, label: 'Ctrl');
      final json = btn.toJson();
      final restored = ToolbarButton.fromJson(json);
      expect(restored.type, ToolbarButtonType.ctrl);
      expect(restored.label, 'Ctrl');
    });

    test('label null par défaut', () {
      const btn = ToolbarButton(type: ToolbarButtonType.arrowUp);
      expect(btn.label, isNull);
    });

    test('defaultToolbarButtons contient 27 boutons', () {
      expect(defaultToolbarButtons().length, 27);
    });

    test('defaultToolbarButtons commence par ctrl, alt, shift', () {
      final buttons = defaultToolbarButtons();
      expect(buttons[0].type, ToolbarButtonType.ctrl);
      expect(buttons[1].type, ToolbarButtonType.alt);
      expect(buttons[2].type, ToolbarButtonType.shift);
    });
  });
}
