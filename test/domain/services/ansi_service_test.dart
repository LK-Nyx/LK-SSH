import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/toolbar_button.dart';
import 'package:lk_ssh/domain/services/ansi_service.dart';

void main() {
  group('AnsiService.sequenceFor', () {
    test('flèche haut → ESC[A', () {
      expect(
        AnsiService.sequenceFor(ToolbarButtonType.arrowUp),
        equals([0x1b, 0x5b, 0x41]),
      );
    });
    test('flèche bas → ESC[B', () {
      expect(
        AnsiService.sequenceFor(ToolbarButtonType.arrowDown),
        equals([0x1b, 0x5b, 0x42]),
      );
    });
    test('flèche droite → ESC[C', () {
      expect(
        AnsiService.sequenceFor(ToolbarButtonType.arrowRight),
        equals([0x1b, 0x5b, 0x43]),
      );
    });
    test('flèche gauche → ESC[D', () {
      expect(
        AnsiService.sequenceFor(ToolbarButtonType.arrowLeft),
        equals([0x1b, 0x5b, 0x44]),
      );
    });
    test('Tab → 0x09', () {
      expect(AnsiService.sequenceFor(ToolbarButtonType.tab), equals([0x09]));
    });
    test('Esc → 0x1b', () {
      expect(AnsiService.sequenceFor(ToolbarButtonType.esc), equals([0x1b]));
    });
    test('F1 → ESC O P', () {
      expect(
        AnsiService.sequenceFor(ToolbarButtonType.f1),
        equals([0x1b, 0x4f, 0x50]),
      );
    });
    test('F5 → ESC[15~', () {
      expect(
        AnsiService.sequenceFor(ToolbarButtonType.f5),
        equals([0x1b, 0x5b, 0x31, 0x35, 0x7e]),
      );
    });
    test('F6 → ESC[17~ (pas 16)', () {
      expect(
        AnsiService.sequenceFor(ToolbarButtonType.f6),
        equals([0x1b, 0x5b, 0x31, 0x37, 0x7e]),
      );
    });
    test('modificateur retourne vide', () {
      expect(AnsiService.sequenceFor(ToolbarButtonType.ctrl), isEmpty);
    });
  });

  group('AnsiService.applyMod', () {
    test('sans mod → UTF-8 direct', () {
      expect(AnsiService.applyMod('a', null), equals([0x61]));
    });
    test('Ctrl+C → 0x03', () {
      expect(AnsiService.applyMod('c', StickyMod.ctrl), equals([0x03]));
    });
    test('Ctrl+D → 0x04', () {
      expect(AnsiService.applyMod('d', StickyMod.ctrl), equals([0x04]));
    });
    test('Ctrl+Z → 0x1a', () {
      expect(AnsiService.applyMod('z', StickyMod.ctrl), equals([0x1a]));
    });
    test('Alt+a → ESC + a', () {
      expect(AnsiService.applyMod('a', StickyMod.alt), equals([0x1b, 0x61]));
    });
    test('data vide → liste vide', () {
      expect(AnsiService.applyMod('', StickyMod.ctrl), isEmpty);
    });
  });
}
