# Terminal Copy/Paste/Zoom — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter le pinch-to-zoom (fontSize persistée + PTY resync), la copie via sélection + menu contextuel, et le collage via menu contextuel + bouton de barre clavier optionnel.

**Architecture:** `_TerminalView` devient `ConsumerStatefulWidget` pour gérer l'état local du zoom et du menu. Le PTY resize hook est ajouté dans `_bindTerminal` (déjà dans `_TerminalScreenState`). Le bouton `paste` est un nouveau `ToolbarButtonType` non inclus dans les défauts.

**Tech Stack:** Flutter, Riverpod, xterm ^4.0.0 (`TerminalController`, `SelectionMode.line`, `onSecondaryTapDown`, `terminal.buffer.getText`), dartssh2 (`SSHSession.resizeTerminal`), `flutter/services.dart` (Clipboard), `dart:async` (Timer)

**APIs xterm 4.x confirmées :**
- `terminal.onResize = (w, h, pw, ph) { … }` — cols×rows + pixels
- `terminal.buffer.getText(selection)` — texte sélectionné
- `terminalController.selection` — `TerminalSelection?`
- `terminalController.clearSelection()` — vide la sélection
- `onSecondaryTapDown: (TapDownDetails details, Offset offset) async { … }` — long press mobile
- `terminal.buffer.getText` prend `TerminalSelection` directement

**API dartssh2 confirmée :**
- `shell.resizeTerminal(int width, int height)` — envoie window-change SSH

---

## Fichiers modifiés / créés

| Fichier | Action |
|---|---|
| `lib/data/models/settings.dart` | Ajouter `terminalFontSize` |
| `lib/data/models/toolbar_button.dart` | Ajouter `paste` à l'enum |
| `lib/domain/services/ansi_service.dart` | Ajouter cas `paste` → `Uint8List(0)` |
| `lib/presentation/screens/terminal_screen.dart` | `_TerminalView` → `ConsumerStatefulWidget` + zoom + copy/paste + PTY resize |
| `lib/presentation/widgets/keyboard_toolbar.dart` | Gérer `paste` dans `_onTap` + `_labelFor` |
| `test/data/models/settings_font_size_test.dart` | Tests serialisation `terminalFontSize` |
| `test/domain/services/ansi_service_paste_test.dart` | Test `sequenceFor(paste)` → vide |

---

## Task 1 : Ajouter `terminalFontSize` à Settings

**Files:**
- Modify: `lib/data/models/settings.dart`
- Create: `test/data/models/settings_font_size_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/data/models/settings_font_size_test.dart
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
```

- [ ] **Step 2 : Lancer le test — vérifier qu'il échoue**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/data/models/settings_font_size_test.dart
```
Attendu : erreur de compilation (champ absent).

- [ ] **Step 3 : Modifier `settings.dart`**

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
    @Default(14.0) double terminalFontSize,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
```

- [ ] **Step 4 : Régénérer le code**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```
Attendu : `settings.freezed.dart` et `settings.g.dart` régénérés.

- [ ] **Step 5 : Lancer le test — vérifier qu'il passe**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/data/models/settings_font_size_test.dart
```
Attendu : `All tests passed!`

- [ ] **Step 6 : Analyse globale**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze
```
Attendu : aucune erreur.

- [ ] **Step 7 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/data/models/settings.dart lib/data/models/settings.freezed.dart lib/data/models/settings.g.dart test/data/models/settings_font_size_test.dart && git commit -m "feat: add terminalFontSize to Settings"
```

---

## Task 2 : Ajouter `paste` à ToolbarButtonType et AnsiService

**Files:**
- Modify: `lib/data/models/toolbar_button.dart`
- Modify: `lib/domain/services/ansi_service.dart`
- Modify: `lib/presentation/widgets/keyboard_toolbar.dart` (label uniquement)
- Create: `test/domain/services/ansi_service_paste_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/domain/services/ansi_service_paste_test.dart
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
    test('paste n\'est pas dans les boutons par défaut', () {
      final types = defaultToolbarButtons().map((b) => b.type).toList();
      expect(types, isNot(contains(ToolbarButtonType.paste)));
    });

    test('defaultToolbarButtons contient toujours 27 boutons', () {
      expect(defaultToolbarButtons().length, 27);
    });
  });
}
```

- [ ] **Step 2 : Lancer le test — vérifier qu'il échoue**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/domain/services/ansi_service_paste_test.dart
```
Attendu : erreur de compilation (`paste` absent de l'enum).

- [ ] **Step 3 : Ajouter `paste` à l'enum dans `toolbar_button.dart`**

Modifier `lib/data/models/toolbar_button.dart` — ajouter `paste` après `password` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'toolbar_button.freezed.dart';
part 'toolbar_button.g.dart';

enum ToolbarButtonType {
  ctrl, alt, shift,
  esc, tab,
  arrowUp, arrowDown, arrowLeft, arrowRight,
  home, end, pageUp, pageDown,
  del,
  f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,
  password,
  paste,
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
  ToolbarButton(type: ToolbarButtonType.del),
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

- [ ] **Step 4 : Ajouter le cas `paste` dans `AnsiService.sequenceFor`**

Dans `lib/domain/services/ansi_service.dart`, le wildcard `_` au bas du switch couvre déjà `paste` et retourne `Uint8List(0)`. Aucun changement nécessaire dans AnsiService — vérifier que le switch compile sans warning exhaustif :

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/domain/services/ansi_service.dart
```
Attendu : aucune erreur (le `_` wildcard couvre `paste`).

- [ ] **Step 5 : Ajouter le label `paste` dans `keyboard_toolbar.dart`**

Dans `lib/presentation/widgets/keyboard_toolbar.dart`, méthode `_labelFor`, ajouter avant la fermeture du switch :

```dart
    ToolbarButtonType.paste      => '⎘',
```

Le switch complet devient (extrait — ajouter la ligne `paste` après `password`) :

```dart
String _labelFor(ToolbarButtonType type) => switch (type) {
  ToolbarButtonType.ctrl       => 'Ctrl',
  ToolbarButtonType.alt        => 'Alt',
  ToolbarButtonType.shift      => 'Shift',
  ToolbarButtonType.esc        => 'Esc',
  ToolbarButtonType.tab        => 'Tab',
  ToolbarButtonType.arrowUp    => '↑',
  ToolbarButtonType.arrowDown  => '↓',
  ToolbarButtonType.arrowLeft  => '←',
  ToolbarButtonType.arrowRight => '→',
  ToolbarButtonType.home       => 'Home',
  ToolbarButtonType.end        => 'End',
  ToolbarButtonType.pageUp     => 'PgUp',
  ToolbarButtonType.pageDown   => 'PgDn',
  ToolbarButtonType.del        => 'Del',
  ToolbarButtonType.f1         => 'F1',
  ToolbarButtonType.f2         => 'F2',
  ToolbarButtonType.f3         => 'F3',
  ToolbarButtonType.f4         => 'F4',
  ToolbarButtonType.f5         => 'F5',
  ToolbarButtonType.f6         => 'F6',
  ToolbarButtonType.f7         => 'F7',
  ToolbarButtonType.f8         => 'F8',
  ToolbarButtonType.f9         => 'F9',
  ToolbarButtonType.f10        => 'F10',
  ToolbarButtonType.f11        => 'F11',
  ToolbarButtonType.f12        => 'F12',
  ToolbarButtonType.password   => '🔑',
  ToolbarButtonType.paste      => '⎘',
};
```

- [ ] **Step 6 : Régénérer le code (enum modifié)**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7 : Lancer les tests — vérifier qu'ils passent**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test test/domain/services/ansi_service_paste_test.dart test/data/models/toolbar_button_test.dart
```
Attendu : tous les tests passent.

- [ ] **Step 8 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/data/models/toolbar_button.dart lib/data/models/toolbar_button.freezed.dart lib/data/models/toolbar_button.g.dart lib/domain/services/ansi_service.dart lib/presentation/widgets/keyboard_toolbar.dart test/domain/services/ansi_service_paste_test.dart && git commit -m "feat: add paste ToolbarButtonType"
```

---

## Task 3 : PTY resize hook dans `_bindTerminal`

**Files:**
- Modify: `lib/presentation/screens/terminal_screen.dart`

Ce task est minimal : ajouter `terminal.onResize` dans `_bindTerminal` pour synchroniser la grille xterm avec le PTY SSH à chaque changement de fontSize.

- [ ] **Step 1 : Ajouter le hook dans `_bindTerminal`**

Dans `lib/presentation/screens/terminal_screen.dart`, méthode `_bindTerminal`, dans le bloc `ok: (shell) {`, après la ligne `terminal.onOutput = (data) { … };`, ajouter :

```dart
        terminal.onResize = (cols, rows, pixelWidth, pixelHeight) {
          shell.resizeTerminal(cols, rows);
        };
```

Le bloc `ok:` complet devient :

```dart
      ok: (shell) {
        _logOk(sessionId, 'Shell prêt — ${conn.server.host}');
        shell.stdout.listen(
          (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        );
        shell.stderr.listen(
          (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        );
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
        terminal.onResize = (cols, rows, pixelWidth, pixelHeight) {
          shell.resizeTerminal(cols, rows);
        };
        shell.done.then((_) {
          if (mounted) _showError('Session terminée par le serveur');
        });
      },
```

- [ ] **Step 2 : Analyser**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/presentation/screens/terminal_screen.dart
```
Attendu : aucune erreur.

- [ ] **Step 3 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/screens/terminal_screen.dart && git commit -m "feat: hook terminal.onResize → shell.resizeTerminal (anti-residual chars)"
```

---

## Task 4 : Zoom pinch-to-zoom dans `_TerminalView`

**Files:**
- Modify: `lib/presentation/screens/terminal_screen.dart`

`_TerminalView` passe de `ConsumerWidget` à `ConsumerStatefulWidget`. On ajoute l'état de zoom et le `GestureDetector`.

- [ ] **Step 1 : Ajouter les imports manquants en tête de fichier**

Dans `lib/presentation/screens/terminal_screen.dart`, la ligne `import 'dart:convert';` existe déjà. Ajouter juste après :

```dart
import 'dart:async';
```

- [ ] **Step 2 : Remplacer la classe `_TerminalView`**

Remplacer entièrement la classe `_TerminalView` (de `class _TerminalView extends ConsumerWidget` jusqu'à la dernière `}`) par :

```dart
class _TerminalView extends ConsumerStatefulWidget {
  const _TerminalView({required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<_TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends ConsumerState<_TerminalView> {
  double _baseSize = 14.0;
  double _pendingSize = 14.0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final fontSize = ref
            .read(settingsNotifierProvider)
            .valueOrNull
            ?.terminalFontSize ??
        14.0;
    _baseSize = fontSize;
    _pendingSize = fontSize;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsNotifierProvider
          .select((s) => s.valueOrNull?.terminalFontSize ?? 14.0),
      (prev, next) {
        if (_debounce == null) setState(() => _pendingSize = next);
      },
    );

    final terminal = ref.watch(terminalProvider(widget.sessionId));

    return GestureDetector(
      onScaleStart: (d) {
        _baseSize = ref
                .read(settingsNotifierProvider)
                .valueOrNull
                ?.terminalFontSize ??
            _pendingSize;
        _pendingSize = _baseSize;
      },
      onScaleUpdate: (d) {
        final next = (_baseSize * d.scale).clamp(8.0, 28.0);
        setState(() => _pendingSize = next);
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          _debounce = null;
          final s =
              ref.read(settingsNotifierProvider).valueOrNull;
          if (s == null || !mounted) return;
          ref
              .read(settingsNotifierProvider.notifier)
              .save(s.copyWith(terminalFontSize: _pendingSize));
        });
      },
      child: TerminalView(
        terminal,
        autofocus: true,
        fontSize: _pendingSize,
        theme: const TerminalTheme(
          cursor: Color(0xFF00FF41),
          selection: Color(0x5000FF41),
          foreground: Color(0xFFCCCCCC),
          background: Color(0xFF0D0D0D),
          black: Color(0xFF000000),
          red: Color(0xFFCC0000),
          green: Color(0xFF00CC44),
          yellow: Color(0xFFCCAA00),
          blue: Color(0xFF0044CC),
          magenta: Color(0xFFCC00CC),
          cyan: Color(0xFF00AACC),
          white: Color(0xFFCCCCCC),
          brightBlack: Color(0xFF555555),
          brightRed: Color(0xFFFF4444),
          brightGreen: Color(0xFF00FF41),
          brightYellow: Color(0xFFFFDD00),
          brightBlue: Color(0xFF4488FF),
          brightMagenta: Color(0xFFFF44FF),
          brightCyan: Color(0xFF44DDFF),
          brightWhite: Color(0xFFFFFFFF),
          searchHitBackground: Color(0x4000FF41),
          searchHitBackgroundCurrent: Color(0x8000FF41),
          searchHitForeground: Color(0xFF000000),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3 : Analyser**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/presentation/screens/terminal_screen.dart
```
Attendu : aucune erreur.

- [ ] **Step 4 : Lancer tous les tests**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test
```
Attendu : tous les tests passent.

- [ ] **Step 5 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/screens/terminal_screen.dart && git commit -m "feat: pinch-to-zoom dans le terminal (fontSize persistée)"
```

---

## Task 5 : Copier / Coller — menu contextuel dans `_TerminalView`

**Files:**
- Modify: `lib/presentation/screens/terminal_screen.dart`

On ajoute `TerminalController`, `ContextMenuController` et la méthode `_showContextMenu` à `_TerminalViewState`.

- [ ] **Step 1 : Ajouter l'import Clipboard**

Dans `lib/presentation/screens/terminal_screen.dart`, ajouter après `import 'dart:async';` :

```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2 : Ajouter les champs à `_TerminalViewState`**

Dans `_TerminalViewState`, après `Timer? _debounce;`, ajouter :

```dart
  final _controller = TerminalController();
  final _contextMenuController = ContextMenuController();
```

- [ ] **Step 3 : Mettre à jour `dispose()`**

Remplacer `dispose()` par :

```dart
  @override
  void dispose() {
    _debounce?.cancel();
    _contextMenuController.remove();
    super.dispose();
  }
```

- [ ] **Step 4 : Ajouter la méthode `_showContextMenu`**

Ajouter la méthode suivante dans `_TerminalViewState`, avant `build` :

```dart
  void _showContextMenu({
    required Offset position,
    String? selectedText,
    String? clipText,
  }) {
    final conn = ref
        .read(sshNotifierProvider(widget.sessionId))
        .valueOrNull;
    final items = [
      if (selectedText != null)
        ContextMenuButtonItem(
          label: 'Copier',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: selectedText));
            _controller.clearSelection();
            _contextMenuController.remove();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copié'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      if (clipText != null && clipText.isNotEmpty)
        ContextMenuButtonItem(
          label: 'Coller',
          onPressed: () {
            conn?.sendRaw(
              Uint8List.fromList(utf8.encode(clipText)),
            );
            _contextMenuController.remove();
          },
        ),
    ];
    if (items.isEmpty) return;
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (_) =>
          AdaptiveTextSelectionToolbar.buttonItems(
        anchors: TextSelectionToolbarAnchors(
          primaryAnchor: position,
        ),
        buttonItems: items,
      ),
    );
  }
```

- [ ] **Step 5 : Mettre à jour `build` — ajouter `controller`, `selectionMode` et `onSecondaryTapDown` à `TerminalView`**

Dans `build`, ajouter `import 'dart:typed_data'` si absent (nécessaire pour `Uint8List`). Puis remplacer le `TerminalView(...)` dans le `GestureDetector` par :

```dart
      child: TerminalView(
        terminal,
        controller: _controller,
        selectionMode: SelectionMode.line,
        autofocus: true,
        fontSize: _pendingSize,
        onSecondaryTapDown: (details, offset) async {
          _contextMenuController.remove();
          final selection = _controller.selection;
          final selectedText = selection != null
              ? terminal.buffer.getText(selection).trim()
              : null;
          final clip =
              await Clipboard.getData(Clipboard.kTextPlain);
          _showContextMenu(
            position: details.globalPosition,
            selectedText:
                (selectedText?.isEmpty ?? true) ? null : selectedText,
            clipText: clip?.text,
          );
        },
        theme: const TerminalTheme(
          cursor: Color(0xFF00FF41),
          selection: Color(0x5000FF41),
          foreground: Color(0xFFCCCCCC),
          background: Color(0xFF0D0D0D),
          black: Color(0xFF000000),
          red: Color(0xFFCC0000),
          green: Color(0xFF00CC44),
          yellow: Color(0xFFCCAA00),
          blue: Color(0xFF0044CC),
          magenta: Color(0xFFCC00CC),
          cyan: Color(0xFF00AACC),
          white: Color(0xFFCCCCCC),
          brightBlack: Color(0xFF555555),
          brightRed: Color(0xFFFF4444),
          brightGreen: Color(0xFF00FF41),
          brightYellow: Color(0xFFFFDD00),
          brightBlue: Color(0xFF4488FF),
          brightMagenta: Color(0xFFFF44FF),
          brightCyan: Color(0xFF44DDFF),
          brightWhite: Color(0xFFFFFFFF),
          searchHitBackground: Color(0x4000FF41),
          searchHitBackgroundCurrent: Color(0x8000FF41),
          searchHitForeground: Color(0xFF000000),
        ),
      ),
```

`Uint8List` est déjà disponible via le `import 'dart:typed_data'` si absent — vérifier les imports en tête de fichier. Si `dart:typed_data` n'est pas importé, l'ajouter.

- [ ] **Step 6 : Analyser**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/presentation/screens/terminal_screen.dart
```
Attendu : aucune erreur.

- [ ] **Step 7 : Lancer tous les tests**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test
```
Attendu : tous les tests passent.

- [ ] **Step 8 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/screens/terminal_screen.dart && git commit -m "feat: copier/coller via long press + menu contextuel dans le terminal"
```

---

## Task 6 : Bouton `paste` dans `KeyboardToolbar`

**Files:**
- Modify: `lib/presentation/widgets/keyboard_toolbar.dart`

- [ ] **Step 1 : Ajouter l'import Clipboard**

Dans `lib/presentation/widgets/keyboard_toolbar.dart`, ajouter parmi les imports existants :

```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2 : Rendre `_onTap` async et gérer `paste`**

Remplacer la signature et le début de `_onTap` :

```dart
  Future<void> _onTap(ToolbarButtonType type) async {
    final notifier = ref.read(keyboardToolbarProvider(widget.sessionId).notifier);
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
    if (type == ToolbarButtonType.paste) {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clip?.text;
      if (text != null && text.isNotEmpty) {
        ref.read(sshNotifierProvider(widget.sessionId)).whenData(
          (conn) => conn?.sendRaw(Uint8List.fromList(utf8.encode(text))),
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
```

Note : l'appel dans `_buildButton` est `onTap: editMode ? null : () => _onTap(btn.type)`. Comme `_onTap` retourne maintenant `Future<void>`, l'appel via une lambda `() => _onTap(...)` est valide (la Future est ignorée silencieusement, ce qui est acceptable pour un callback UI sans gestion d'erreur asynchrone).

- [ ] **Step 3 : Analyser**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter analyze lib/presentation/widgets/keyboard_toolbar.dart
```
Attendu : aucune erreur.

- [ ] **Step 4 : Lancer tous les tests**

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter test
```
Attendu : tous les tests passent.

- [ ] **Step 5 : Commit**

```bash
cd /home/lararchfr/code/LK-SSH && git add lib/presentation/widgets/keyboard_toolbar.dart && git commit -m "feat: bouton paste dans la barre clavier"
```

---

## Vérification finale

- [ ] Déployer et tester manuellement :

```bash
cd /home/lararchfr/code/LK-SSH && /home/lararchfr/.local/flutter/bin/flutter run
```

**Checklist manuelle :**
- [ ] Pinch-to-zoom : zoom in/out → terminal reflow sans caractères résiduels
- [ ] Redémarrage app → fontSize retrouvée (persistée dans Settings)
- [ ] Zoom très petit (8px) et très grand (28px) → pas de crash, clamped
- [ ] Long press sur le terminal sans sélection, presse-papier non vide → menu "Coller"
- [ ] Long press après avoir sélectionné du texte (drag) → menu "Copier" + "Coller"
- [ ] "Copier" → snackbar "Copié" → coller ailleurs confirme le texte
- [ ] "Coller" depuis menu → texte injecté dans le shell
- [ ] Bouton `⎘` dans la barre (après l'avoir ajouté via +) → colle depuis le presse-papier
- [ ] PTY resize : zoom, puis taper `echo $COLUMNS` → retourne la bonne valeur
