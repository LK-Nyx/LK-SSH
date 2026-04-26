import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/domain/services/ansi_service.dart';
import 'package:lk_ssh/presentation/providers/keyboard_toolbar_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('KeyboardToolbarNotifier', () {
    test('état initial : pas de mod actif, pas en mode édition', () {
      final c = makeContainer();
      final state = c.read(keyboardToolbarProvider('s1'));
      expect(state.activeMod, isNull);
      expect(state.editMode, isFalse);
    });

    test('toggleMod(ctrl) active ctrl', () {
      final c = makeContainer();
      c.read(keyboardToolbarProvider('s1').notifier).toggleMod(StickyMod.ctrl);
      expect(c.read(keyboardToolbarProvider('s1')).activeMod, StickyMod.ctrl);
    });

    test('toggleMod(ctrl) deux fois désactive', () {
      final c = makeContainer();
      final n = c.read(keyboardToolbarProvider('s1').notifier);
      n.toggleMod(StickyMod.ctrl);
      n.toggleMod(StickyMod.ctrl);
      expect(c.read(keyboardToolbarProvider('s1')).activeMod, isNull);
    });

    test('toggleMod remplace le mod précédent', () {
      final c = makeContainer();
      final n = c.read(keyboardToolbarProvider('s1').notifier);
      n.toggleMod(StickyMod.ctrl);
      n.toggleMod(StickyMod.alt);
      expect(c.read(keyboardToolbarProvider('s1')).activeMod, StickyMod.alt);
    });

    test('clearMod remet activeMod à null', () {
      final c = makeContainer();
      final n = c.read(keyboardToolbarProvider('s1').notifier);
      n.toggleMod(StickyMod.shift);
      n.clearMod();
      expect(c.read(keyboardToolbarProvider('s1')).activeMod, isNull);
    });

    test('toggleEditMode bascule editMode', () {
      final c = makeContainer();
      final n = c.read(keyboardToolbarProvider('s1').notifier);
      n.toggleEditMode();
      expect(c.read(keyboardToolbarProvider('s1')).editMode, isTrue);
      n.toggleEditMode();
      expect(c.read(keyboardToolbarProvider('s1')).editMode, isFalse);
    });

    test('providers de sessions différentes sont indépendants', () {
      final c = makeContainer();
      c.read(keyboardToolbarProvider('s1').notifier).toggleMod(StickyMod.ctrl);
      expect(c.read(keyboardToolbarProvider('s2')).activeMod, isNull);
    });
  });
}
