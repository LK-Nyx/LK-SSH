# Keyboard Toolbar — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter une barre de touches spéciales scrollable, personnalisable et avec modificateurs sticky (Ctrl/Alt/Shift) entre le terminal et le SnippetPanel.

**Architecture:** Un modèle `ToolbarButton` persisté dans `Settings`, un `KeyboardToolbarNotifier` Riverpod qui gère l'état sticky et le mode édition, et un widget `KeyboardToolbar` qui envoie les séquences ANSI via `SshConnection.sendRaw()`. L'interception des modificateurs sticky se fait en wrappant `terminal.onOutput` dans `_bindTerminal`.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation), freezed, json_serializable, flutter_secure_storage, xterm, dartssh2

---

## Fichiers créés / modifiés

| Fichier | Action | Rôle |
|---|---|---|
| `lib/data/models/toolbar_button.dart` | Créer | ToolbarButtonType enum + ToolbarButton freezed model + defaultToolbarButtons() |
| `lib/data/ssh/toolbar_password_storage.dart` | Créer | Lecture/écriture `toolbar_password` dans FlutterSecureStorage |
| `lib/domain/services/ansi_service.dart` | Créer | Fonctions pures : sequenceFor() + applyMod() |
| `lib/presentation/providers/keyboard_toolbar_provider.dart` | Créer | StickyMod enum + KeyboardToolbarState + KeyboardToolbarNotifier |
| `lib/presentation/widgets/keyboard_toolbar.dart` | Créer | Widget complet (mode normal + mode édition) |
| `lib/data/models/settings.dart` | Modifier | Ajouter toolbarButtons + fixedNavSection |
| `lib/domain/services/ssh_service.dart` | Modifier | Ajouter SshConnection.sendRaw() |
| `lib/presentation/screens/terminal_screen.dart` | Modifier | Ajouter KeyboardToolbar + wrapper terminal.onOutput |
| `lib/presentation/screens/settings_screen.dart` | Modifier | Champ mot de passe + toggle fixedNavSection + reset |
| `test/data/models/toolbar_button_test.dart` | Créer | Tests sérialisation ToolbarButton |
| `test/domain/services/ansi_service_test.dart` | Créer | Tests séquences ANSI + applyMod |
| `test/presentation/providers/keyboard_toolbar_provider_test.dart` | Créer | Tests sticky mod + editMode |

---

## Task 1 : ToolbarButton model

**Files:**
- Create: `lib/data/models/toolbar_button.dart`
- Create: `test/data/models/toolbar_button_test.dart`

- [ ] **Step 1 : Écrire le test de sérialisation**

```dart
// test/data/models/toolbar_button_test.dart
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
```

- [ ] **Step 2 : Lancer le test — vérifier qu'il échoue**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/data/models/toolbar_button_test.dart
```
Attendu : erreur de compilation (fichier source absent).

- [ ] **Step 3 : Créer le modèle**

```dart
// lib/data/models/toolbar_button.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'toolbar_button.freezed.dart';
part 'toolbar_button.g.dart';

enum ToolbarButtonType {
  ctrl, alt, shift,
  esc, tab,
  arrowUp, arrowDown, arrowLeft, arrowRight,
  home, end, pageUp, pageDown,
  f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,
  password,
}

@freezed
class ToolbarButton with _$ToolbarButton {
  const factory ToolbarButton({
    required ToolbarButtonType type,
    String? label,
  }) = _ToolbarButton;

  factory ToolbarButton.fromJson(Map<String, dynamic> json) =>
      _$ToolbarButtonFromJson(json);
}

List<ToolbarButton> defaultToolbarButtons() => const [
  ToolbarButton(type: ToolbarButtonType.ctrl),
  ToolbarButton(type: ToolbarButtonType.alt),
  ToolbarButton(type: ToolbarButtonType.shift),
  ToolbarButton(type: ToolbarButtonType.esc),
  ToolbarButton(type: ToolbarButtonType.tab),
  ToolbarButton(type: ToolbarButtonType.arrowUp),
  ToolbarButton(type: ToolbarButtonType.arrowDown),
  ToolbarButton(type: ToolbarButtonType.arrowLeft),
  ToolbarButton(type: ToolbarButtonType.arrowRight),
  ToolbarButton(type: ToolbarButtonType.home),
  ToolbarButton(type: ToolbarButtonType.end),
  ToolbarButton(type: ToolbarButtonType.pageUp),
  ToolbarButton(type: ToolbarButtonType.pageDown),
  ToolbarButton(type: ToolbarButtonType.password),
  ToolbarButton(type: ToolbarButtonType.f1),
  ToolbarButton(type: ToolbarButtonType.f2),
  ToolbarButton(type: ToolbarButtonType.f3),
  ToolbarButton(type: ToolbarButtonType.f4),
  ToolbarButton(type: ToolbarButtonType.f5),
  ToolbarButton(type: ToolbarButtonType.f6),
  ToolbarButton(type: ToolbarButtonType.f7),
  ToolbarButton(type: ToolbarButtonType.f8),
  ToolbarButton(type: ToolbarButtonType.f9),
  ToolbarButton(type: ToolbarButtonType.f10),
  ToolbarButton(type: ToolbarButtonType.f11),
  ToolbarButton(type: ToolbarButtonType.f12),
];
```

- [ ] **Step 4 : Générer le code freezed**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```
Attendu : création de `toolbar_button.freezed.dart` et `toolbar_button.g.dart`.

- [ ] **Step 5 : Lancer le test — vérifier qu'il passe**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/data/models/toolbar_button_test.dart
```
Attendu : `All tests passed!`

- [ ] **Step 6 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/data/models/toolbar_button.dart lib/data/models/toolbar_button.freezed.dart lib/data/models/toolbar_button.g.dart test/data/models/toolbar_button_test.dart && git commit -m "feat: add ToolbarButton model"
```

---

## Task 2 : AnsiService

**Files:**
- Create: `lib/domain/services/ansi_service.dart`
- Create: `test/domain/services/ansi_service_test.dart`

- [ ] **Step 1 : Écrire les tests**

```dart
// test/domain/services/ansi_service_test.dart
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
```

- [ ] **Step 2 : Lancer le test — vérifier qu'il échoue**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/domain/services/ansi_service_test.dart
```
Attendu : erreur de compilation (fichier source absent).

- [ ] **Step 3 : Créer AnsiService**

```dart
// lib/domain/services/ansi_service.dart
import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/toolbar_button.dart';

enum StickyMod { ctrl, alt, shift }

// ignore: avoid_classes_with_only_static_members
final class AnsiService {
  AnsiService._();

  static Uint8List sequenceFor(ToolbarButtonType type) => switch (type) {
    ToolbarButtonType.arrowUp    => _s('\x1b[A'),
    ToolbarButtonType.arrowDown  => _s('\x1b[B'),
    ToolbarButtonType.arrowRight => _s('\x1b[C'),
    ToolbarButtonType.arrowLeft  => _s('\x1b[D'),
    ToolbarButtonType.home       => _s('\x1b[H'),
    ToolbarButtonType.end        => _s('\x1b[F'),
    ToolbarButtonType.pageUp     => _s('\x1b[5~'),
    ToolbarButtonType.pageDown   => _s('\x1b[6~'),
    ToolbarButtonType.esc        => _s('\x1b'),
    ToolbarButtonType.tab        => _s('\t'),
    ToolbarButtonType.f1         => _s('\x1bOP'),
    ToolbarButtonType.f2         => _s('\x1bOQ'),
    ToolbarButtonType.f3         => _s('\x1bOR'),
    ToolbarButtonType.f4         => _s('\x1bOS'),
    ToolbarButtonType.f5         => _s('\x1b[15~'),
    ToolbarButtonType.f6         => _s('\x1b[17~'),
    ToolbarButtonType.f7         => _s('\x1b[18~'),
    ToolbarButtonType.f8         => _s('\x1b[19~'),
    ToolbarButtonType.f9         => _s('\x1b[20~'),
    ToolbarButtonType.f10        => _s('\x1b[21~'),
    ToolbarButtonType.f11        => _s('\x1b[23~'),
    ToolbarButtonType.f12        => _s('\x1b[24~'),
    _                            => Uint8List(0),
  };

  static Uint8List applyMod(String data, StickyMod? mod) {
    if (data.isEmpty) return Uint8List(0);
    if (mod == null) return Uint8List.fromList(utf8.encode(data));
    final code = data.codeUnitAt(0);
    return switch (mod) {
      StickyMod.ctrl  => Uint8List.fromList([code & 0x1F]),
      StickyMod.alt   => Uint8List.fromList([0x1B, ...utf8.encode(data)]),
      StickyMod.shift => Uint8List.fromList(utf8.encode(data.toUpperCase())),
    };
  }

  static Uint8List _s(String seq) => Uint8List.fromList(seq.codeUnits);
}
```

**Note :** les imports absolus seront corrigés en imports relatifs après vérification de la structure.

- [ ] **Step 4 : Mettre à jour keyboard_toolbar_provider.dart pour importer StickyMod depuis AnsiService**

`StickyMod` est défini dans `ansi_service.dart`. Dans `keyboard_toolbar_provider.dart` (Task 5), ajouter l'import :
```dart
import '../../domain/services/ansi_service.dart';
```
Et supprimer la déclaration locale de `StickyMod`.

- [ ] **Step 5 : Lancer le test — vérifier qu'il passe**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/domain/services/ansi_service_test.dart
```
Attendu : `All tests passed!`

- [ ] **Step 6 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/domain/services/ansi_service.dart test/domain/services/ansi_service_test.dart && git commit -m "feat: add AnsiService (sequences + sticky mod application)"
```

---

## Task 3 : Mettre à jour Settings

**Files:**
- Modify: `lib/data/models/settings.dart`

- [ ] **Step 1 : Ajouter les champs à Settings**

Remplacer le contenu de `lib/data/models/settings.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'toolbar_button.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

enum KeyStorageMode { secureStorage, passphraseProtected }

enum AppTheme { dark, light }

@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(KeyStorageMode.secureStorage) KeyStorageMode keyStorageMode,
    @Default(5) int sessionTimeoutMinutes,
    @Default(AppTheme.dark) AppTheme theme,
    @Default(false) bool verboseLogging,
    @Default([]) List<ToolbarButton> toolbarButtons,
    @Default(false) bool fixedNavSection,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
```

- [ ] **Step 2 : Régénérer le code freezed**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```
Attendu : `settings.freezed.dart` et `settings.g.dart` régénérés sans erreur.

- [ ] **Step 3 : Vérifier la compilation**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze
```
Attendu : aucune erreur.

- [ ] **Step 4 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/data/models/settings.dart lib/data/models/settings.freezed.dart lib/data/models/settings.g.dart && git commit -m "feat: add toolbarButtons and fixedNavSection to Settings"
```

---

## Task 4 : ToolbarPasswordStorage

**Files:**
- Create: `lib/data/ssh/toolbar_password_storage.dart`

- [ ] **Step 1 : Créer la classe**

```dart
// lib/data/ssh/toolbar_password_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class ToolbarPasswordStorage {
  static const _key = 'toolbar_password';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> load() => _storage.read(key: _key);

  Future<void> save(String password) =>
      _storage.write(key: _key, value: password);

  Future<void> delete() => _storage.delete(key: _key);
}
```

- [ ] **Step 2 : Vérifier la compilation**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/data/ssh/toolbar_password_storage.dart
```
Attendu : aucune erreur.

- [ ] **Step 3 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/data/ssh/toolbar_password_storage.dart && git commit -m "feat: add ToolbarPasswordStorage"
```

---

## Task 5 : KeyboardToolbarNotifier

**Files:**
- Create: `lib/presentation/providers/keyboard_toolbar_provider.dart`
- Create: `test/presentation/providers/keyboard_toolbar_provider_test.dart`

- [ ] **Step 1 : Écrire les tests**

```dart
// test/presentation/providers/keyboard_toolbar_provider_test.dart
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
```

- [ ] **Step 2 : Lancer le test — vérifier qu'il échoue**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/presentation/providers/keyboard_toolbar_provider_test.dart
```
Attendu : erreur de compilation (fichier source absent).

- [ ] **Step 3 : Créer le provider**

```dart
// lib/presentation/providers/keyboard_toolbar_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/ansi_service.dart';

part 'keyboard_toolbar_provider.g.dart';

class KeyboardToolbarState {
  const KeyboardToolbarState({this.activeMod, this.editMode = false});
  final StickyMod? activeMod;
  final bool editMode;
}

@riverpod
class KeyboardToolbarNotifier extends _$KeyboardToolbarNotifier {
  @override
  KeyboardToolbarState build(String sessionId) =>
      const KeyboardToolbarState();

  void toggleMod(StickyMod mod) {
    state = KeyboardToolbarState(
      activeMod: state.activeMod == mod ? null : mod,
      editMode: state.editMode,
    );
  }

  void clearMod() {
    state = KeyboardToolbarState(editMode: state.editMode);
  }

  void toggleEditMode() {
    state = KeyboardToolbarState(
      activeMod: state.activeMod,
      editMode: !state.editMode,
    );
  }
}
```

- [ ] **Step 4 : Générer le code Riverpod**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```
Attendu : `keyboard_toolbar_provider.g.dart` créé.

- [ ] **Step 5 : Lancer les tests — vérifier qu'ils passent**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/presentation/providers/keyboard_toolbar_provider_test.dart
```
Attendu : `All tests passed!`

- [ ] **Step 6 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/providers/keyboard_toolbar_provider.dart lib/presentation/providers/keyboard_toolbar_provider.g.dart test/presentation/providers/keyboard_toolbar_provider_test.dart && git commit -m "feat: add KeyboardToolbarNotifier (sticky mods + edit mode)"
```

---

## Task 6 : SshConnection.sendRaw()

**Files:**
- Modify: `lib/domain/services/ssh_service.dart`

- [ ] **Step 1 : Ajouter sendRaw() à SshConnection**

Dans `lib/domain/services/ssh_service.dart`, après `sendCommand` :

```dart
void sendRaw(Uint8List bytes) {
  _activeShell?.write(bytes);
}
```

Le bloc `SshConnection` complet devient :

```dart
final class SshConnection {
  SshConnection({required this.client, required this.server});

  final SSHClient client;
  final Server server;
  SSHSession? _activeShell;

  Future<Result<SSHSession, AppError>> openShell({
    int width = 80,
    int height = 24,
  }) async {
    try {
      final shell = await client.shell(
        pty: SSHPtyConfig(width: width, height: height),
      );
      _activeShell = shell;
      return Ok(shell);
    } catch (e) {
      return Err(SshConnectionError(e.toString()));
    }
  }

  void sendCommand(String command) {
    _activeShell?.write(Uint8List.fromList(utf8.encode('$command\n')));
  }

  void sendRaw(Uint8List bytes) {
    _activeShell?.write(bytes);
  }

  void close() => client.close();
}
```

- [ ] **Step 2 : Vérifier la compilation**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/domain/services/ssh_service.dart
```
Attendu : aucune erreur.

- [ ] **Step 3 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/domain/services/ssh_service.dart && git commit -m "feat: add SshConnection.sendRaw()"
```

---

## Task 7 : KeyboardToolbar widget

**Files:**
- Create: `lib/presentation/widgets/keyboard_toolbar.dart`

- [ ] **Step 1 : Créer le widget**

```dart
// lib/presentation/widgets/keyboard_toolbar.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/toolbar_button.dart';
import '../../data/models/settings.dart';
import '../../data/ssh/toolbar_password_storage.dart';
import '../../domain/services/ansi_service.dart';
import '../providers/keyboard_toolbar_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ssh_provider.dart';

class KeyboardToolbar extends ConsumerStatefulWidget {
  const KeyboardToolbar({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<KeyboardToolbar> createState() => _KeyboardToolbarState();
}

class _KeyboardToolbarState extends ConsumerState<KeyboardToolbar> {
  String? _password;
  final _pwStorage = ToolbarPasswordStorage();

  @override
  void initState() {
    super.initState();
    _pwStorage.load().then((pw) {
      if (mounted) setState(() => _password = pw);
    });
  }

  List<ToolbarButton> _buttons(Settings? settings) {
    final list = settings?.toolbarButtons ?? [];
    return list.isEmpty ? defaultToolbarButtons() : list;
  }

  bool _isModifier(ToolbarButtonType t) =>
      t == ToolbarButtonType.ctrl ||
      t == ToolbarButtonType.alt ||
      t == ToolbarButtonType.shift;

  StickyMod? _modFor(ToolbarButtonType t) => switch (t) {
    ToolbarButtonType.ctrl  => StickyMod.ctrl,
    ToolbarButtonType.alt   => StickyMod.alt,
    ToolbarButtonType.shift => StickyMod.shift,
    _ => null,
  };

  void _onTap(ToolbarButtonType type) {
    final notifier =
        ref.read(keyboardToolbarProvider(widget.sessionId).notifier);
    final mod = _modFor(type);
    if (mod != null) { notifier.toggleMod(mod); return; }
    if (type == ToolbarButtonType.password) {
      final pw = _password;
      if (pw != null && pw.isNotEmpty) {
        ref.read(sshNotifierProvider(widget.sessionId)).whenData(
          (conn) => conn?.sendRaw(Uint8List.fromList(utf8.encode('$pw\n'))),
        );
      }
      return;
    }
    final bytes = AnsiService.sequenceFor(type);
    if (bytes.isNotEmpty) {
      ref.read(sshNotifierProvider(widget.sessionId)).whenData(
        (conn) => conn?.sendRaw(bytes),
      );
    }
  }

  void _onDelete(int index, List<ToolbarButton> buttons, Settings settings) {
    final updated = [...buttons]..removeAt(index);
    ref.read(settingsNotifierProvider.notifier)
        .save(settings.copyWith(toolbarButtons: updated));
  }

  void _onReorder(
    int oldIndex,
    int newIndex,
    List<ToolbarButton> buttons,
    Settings settings,
  ) {
    final updated = [...buttons];
    if (newIndex > oldIndex) newIndex--;
    updated.insert(newIndex, updated.removeAt(oldIndex));
    ref.read(settingsNotifierProvider.notifier)
        .save(settings.copyWith(toolbarButtons: updated));
  }

  void _showAddSheet(List<ToolbarButton> current, Settings settings) {
    final currentTypes = current.map((b) => b.type).toSet();
    final available = defaultToolbarButtons()
        .where((b) => !currentTypes.contains(b.type))
        .toList();
    if (available.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Ajouter un bouton',
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          ...available.map(
            (btn) => ListTile(
              title: Text(
                _labelFor(btn.type),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              onTap: () {
                ref.read(settingsNotifierProvider.notifier).save(
                  settings.copyWith(
                    toolbarButtons: [...current, btn],
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(ToolbarButtonType type) => switch (type) {
    ToolbarButtonType.ctrl      => 'Ctrl',
    ToolbarButtonType.alt       => 'Alt',
    ToolbarButtonType.shift     => 'Shift',
    ToolbarButtonType.esc       => 'Esc',
    ToolbarButtonType.tab       => 'Tab',
    ToolbarButtonType.arrowUp   => '↑',
    ToolbarButtonType.arrowDown => '↓',
    ToolbarButtonType.arrowLeft => '←',
    ToolbarButtonType.arrowRight => '→',
    ToolbarButtonType.home      => 'Home',
    ToolbarButtonType.end       => 'End',
    ToolbarButtonType.pageUp    => 'PgUp',
    ToolbarButtonType.pageDown  => 'PgDn',
    ToolbarButtonType.f1        => 'F1',
    ToolbarButtonType.f2        => 'F2',
    ToolbarButtonType.f3        => 'F3',
    ToolbarButtonType.f4        => 'F4',
    ToolbarButtonType.f5        => 'F5',
    ToolbarButtonType.f6        => 'F6',
    ToolbarButtonType.f7        => 'F7',
    ToolbarButtonType.f8        => 'F8',
    ToolbarButtonType.f9        => 'F9',
    ToolbarButtonType.f10       => 'F10',
    ToolbarButtonType.f11       => 'F11',
    ToolbarButtonType.f12       => 'F12',
    ToolbarButtonType.password  => '🔑',
  };

  Widget _buildButton({
    required ToolbarButton btn,
    required bool isActive,
    required bool editMode,
    required int index,
    required List<ToolbarButton> buttons,
    required Settings settings,
  }) {
    final label = btn.label ?? _labelFor(btn.type);
    return GestureDetector(
      key: ValueKey(btn.type),
      onTap: editMode ? null : () => _onTap(btn.type),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            margin:
                const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF00FF41)
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isActive ? Colors.black : Colors.white,
              ),
            ),
          ),
          if (editMode)
            Positioned(
              top: 2,
              right: 0,
              child: GestureDetector(
                onTap: () => _onDelete(index, buttons, settings),
                child: const CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 9, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsNotifierProvider).valueOrNull;
    final toolbarState =
        ref.watch(keyboardToolbarProvider(widget.sessionId));
    final buttons = _buttons(settings);
    final editMode = toolbarState.editMode;
    final activeMod = toolbarState.activeMod;
    final fixedNav = settings?.fixedNavSection ?? false;

    final navTypes = {
      ToolbarButtonType.arrowUp,
      ToolbarButtonType.arrowDown,
      ToolbarButtonType.arrowLeft,
      ToolbarButtonType.arrowRight,
      ToolbarButtonType.esc,
      ToolbarButtonType.tab,
    };

    List<ToolbarButton> navButtons = [];
    List<ToolbarButton> scrollButtons = buttons;

    if (fixedNav && !editMode) {
      navButtons =
          buttons.where((b) => navTypes.contains(b.type)).toList();
      scrollButtons =
          buttons.where((b) => !navTypes.contains(b.type)).toList();
    }

    Widget buildBtn(ToolbarButton btn, int globalIndex) => _buildButton(
          btn: btn,
          isActive: _isModifier(btn.type) &&
              _modFor(btn.type) == activeMod,
          editMode: editMode,
          index: globalIndex,
          buttons: buttons,
          settings: settings ?? const Settings(),
        );

    Widget scrollable = editMode
        ? SizedBox(
            height: 44,
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              onReorder: (o, n) => _onReorder(
                  o, n, buttons, settings ?? const Settings()),
              children: [
                for (int i = 0; i < buttons.length; i++)
                  buildBtn(buttons[i], i),
              ],
            ),
          )
        : ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < scrollButtons.length; i++)
                buildBtn(scrollButtons[i], i),
              if (editMode)
                IconButton(
                  icon: const Icon(Icons.add,
                      size: 16, color: Color(0xFF00FF41)),
                  onPressed: () => _showAddSheet(
                      buttons, settings ?? const Settings()),
                ),
            ],
          );

    return GestureDetector(
      onLongPress: () => ref
          .read(keyboardToolbarProvider(widget.sessionId).notifier)
          .toggleEditMode(),
      child: Container(
        height: 44,
        color: editMode
            ? const Color(0xFF252525)
            : const Color(0xFF1A1A1A),
        child: fixedNav && !editMode && navButtons.isNotEmpty
            ? Row(
                children: [
                  Row(
                    children: navButtons
                        .map((b) => buildBtn(b, buttons.indexOf(b)))
                        .toList(),
                  ),
                  const VerticalDivider(
                      width: 1, color: Color(0xFF3A3A3A)),
                  Expanded(child: scrollable),
                ],
              )
            : Row(
                children: [
                  Expanded(child: scrollable),
                  if (editMode)
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add,
                          size: 16, color: Color(0xFF00FF41)),
                      onPressed: () => _showAddSheet(
                          buttons, settings ?? const Settings()),
                    ),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 2 : Vérifier la compilation**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/presentation/widgets/keyboard_toolbar.dart
```
Attendu : aucune erreur.

- [ ] **Step 3 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/widgets/keyboard_toolbar.dart && git commit -m "feat: add KeyboardToolbar widget (normal + edit mode)"
```

---

## Task 8 : Intégrer dans terminal_screen.dart

**Files:**
- Modify: `lib/presentation/screens/terminal_screen.dart`

- [ ] **Step 1 : Ajouter l'import du toolbar**

En haut de `terminal_screen.dart`, ajouter :

```dart
import '../../domain/services/ansi_service.dart';
import '../providers/keyboard_toolbar_provider.dart';
import '../widgets/keyboard_toolbar.dart';
```

- [ ] **Step 2 : Wrapper terminal.onOutput dans _bindTerminal**

Remplacer dans `_bindTerminal` :

```dart
terminal.onOutput = (data) =>
    shell.write(Uint8List.fromList(utf8.encode(data)));
```

Par :

```dart
terminal.onOutput = (data) {
  final mod =
      ref.read(keyboardToolbarProvider(sessionId)).activeMod;
  final bytes = AnsiService.applyMod(data, mod);
  if (mod != null) {
    ref
        .read(keyboardToolbarProvider(sessionId).notifier)
        .clearMod();
  }
  shell.write(bytes);
};
```

- [ ] **Step 3 : Ajouter KeyboardToolbar dans build()**

Dans `_TerminalScreenState.build()`, dans la `Column` enfant de `SafeArea`, insérer `KeyboardToolbar` entre `TerminalView` et `SnippetPanel` :

```dart
Column(
  children: [
    _SessionTabBar(
      sessions: sessions,
      activeId: _activeSessionId,
      onSelect: (id) => setState(() => _activeSessionId = id),
      onAdd: _openNewSession,
      onClose: _closeSession,
    ),
    Expanded(
      child: _TerminalView(sessionId: _activeSessionId),
    ),
    KeyboardToolbar(sessionId: _activeSessionId),   // ← nouveau
    SnippetPanel(
      sessionId: _activeSessionId,
      serverId: activeSession.serverId,
    ),
  ],
),
```

- [ ] **Step 4 : Vérifier la compilation**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/presentation/screens/terminal_screen.dart
```
Attendu : aucune erreur.

- [ ] **Step 5 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/screens/terminal_screen.dart && git commit -m "feat: integrate KeyboardToolbar into terminal screen"
```

---

## Task 9 : Mettre à jour settings_screen.dart

**Files:**
- Modify: `lib/presentation/screens/settings_screen.dart`

- [ ] **Step 1 : Ajouter l'import ToolbarPasswordStorage**

En haut de `settings_screen.dart` :

```dart
import '../../data/ssh/toolbar_password_storage.dart';
import '../../data/models/toolbar_button.dart';
```

- [ ] **Step 2 : Ajouter l'état pour le mot de passe toolbar dans _SettingsBodyState**

Dans `_SettingsBodyState`, ajouter :

```dart
final _pwStorage = ToolbarPasswordStorage();
final _pwCtrl = TextEditingController();
bool _pwLoaded = false;

@override
void dispose() {
  _pwCtrl.dispose();
  super.dispose();
}
```

Et dans `initState`, après `_checkKeyLoaded()` :

```dart
_pwStorage.load().then((pw) {
  if (mounted && pw != null) {
    _pwCtrl.text = '••••••••';
    setState(() => _pwLoaded = pw.isNotEmpty);
  }
});
```

- [ ] **Step 3 : Ajouter la section "Barre clavier" dans le build de _SettingsBodyState**

Dans la `ListView` du `build`, ajouter après la section "Débogage" :

```dart
const Divider(),
const _SectionHeader('Barre clavier'),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: TextField(
    controller: _pwCtrl,
    obscureText: true,
    decoration: const InputDecoration(
      labelText: 'Mot de passe (touche 🔑)',
      border: OutlineInputBorder(),
      helperText: 'Envoyé tel quel au shell via la touche mot de passe',
    ),
    onSubmitted: (pw) async {
      if (pw.isNotEmpty) {
        await _pwStorage.save(pw);
        if (mounted) setState(() => _pwLoaded = true);
      }
    },
  ),
),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            final pw = _pwCtrl.text;
            if (pw.isNotEmpty && pw != '••••••••') {
              await _pwStorage.save(pw);
              if (mounted) setState(() => _pwLoaded = true);
            }
          },
          child: const Text('Enregistrer le mot de passe'),
        ),
      ),
    ],
  ),
),
SwitchListTile(
  title: const Text('Section navigation fixe'),
  subtitle: const Text(
    'Épingle ↑↓←→ Esc Tab à gauche de la barre',
  ),
  value: widget.settings.fixedNavSection,
  activeColor: const Color(0xFF00FF41),
  onChanged: (v) => ref
      .read(settingsNotifierProvider.notifier)
      .save(widget.settings.copyWith(fixedNavSection: v)),
),
ListTile(
  title: const Text('Réinitialiser la barre clavier'),
  subtitle: const Text('Remet les boutons par défaut'),
  trailing: const Icon(Icons.refresh, color: Colors.grey),
  onTap: () => ref
      .read(settingsNotifierProvider.notifier)
      .save(widget.settings.copyWith(toolbarButtons: [])),
),
```

- [ ] **Step 4 : Vérifier la compilation**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/presentation/screens/settings_screen.dart
```
Attendu : aucune erreur.

- [ ] **Step 5 : Analyse globale**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze
```
Attendu : aucune erreur.

- [ ] **Step 6 : Lancer tous les tests**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test
```
Attendu : tous les tests passent.

- [ ] **Step 7 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/screens/settings_screen.dart && git commit -m "feat: add toolbar password + fixedNavSection settings"
```

---

## Vérification finale

- [ ] Déployer sur le téléphone et tester :

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter run
```

**Checklist manuelle :**
- [ ] La barre apparaît entre le terminal et les snippets (44px)
- [ ] Tap `Ctrl` → bouton en vert → taper `c` sur le clavier → `^C` envoyé → Ctrl revient en gris
- [ ] Tap `↑` envoie la flèche dans le shell (historique ZSH)
- [ ] Tap `Tab` complète une commande
- [ ] Tap `🔑` envoie le mot de passe configuré dans Settings + `\n`
- [ ] Long press sur la barre → mode édition (fond gris foncé)
- [ ] En mode édition : croix sur chaque bouton → suppression
- [ ] En mode édition : bouton `+` → bottom sheet avec boutons disponibles
- [ ] En mode édition : drag & drop pour réordonner
- [ ] Long press à nouveau → quitte le mode édition
- [ ] Activer "Section navigation fixe" dans Settings → flèches + Esc + Tab épinglés à gauche
- [ ] "Réinitialiser la barre clavier" remet le défaut usine
