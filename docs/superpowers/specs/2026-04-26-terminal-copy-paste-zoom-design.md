# Terminal — Copier / Coller / Zoom — Design Spec
Date: 2026-04-26

## Objectif

Ajouter dans le terminal SSH :
- **Zoom** (pinch-to-zoom, fontSize persistée, PTY resync pour éviter les caractères résiduels)
- **Copier** (long press → sélection → menu contextuel flottant)
- **Coller** (menu contextuel + bouton optionnel dans la barre clavier)

L'approche choisie (A) utilise les primitives natives de xterm 4.x et le `AdaptiveTextSelectionToolbar` de Flutter. Une refonte visuelle complète des handles de sélection (approche B) est identifiée comme axe d'amélioration majeur futur.

---

## 1. Modèle de données

### Ajout à `Settings`

```dart
@Default(14.0) double terminalFontSize,
```

- Persisté via freezed/json_serializable dans les settings existants
- Aucune migration nécessaire (valeur par défaut appliquée si absent)
- Plage valide : 8.0–28.0

### Ajout à `ToolbarButtonType`

```dart
enum ToolbarButtonType {
  // ... existants ...
  password,
  paste,   // ← nouveau
}
```

- **Non inclus** dans `defaultToolbarButtons()` (long press couvre le cas principal)
- Disponible dans le menu "Ajouter un bouton" de la barre clavier
- `AnsiService.sequenceFor(paste)` → `Uint8List(0)` (géré directement dans `_onTap`)
- `_labelFor(paste)` → `'⎘'`

---

## 2. Zoom

### État

`_TerminalView` devient `ConsumerStatefulWidget` avec :

```dart
double _baseSize = 14.0;   // snapshot au début du pinch
double _pendingSize = 14.0; // valeur en cours, throttlée avant save
Timer? _debounce;
```

### Geste pinch

```dart
GestureDetector(
  onScaleStart: (d) {
    _baseSize = ref.read(settingsNotifierProvider).valueOrNull?.terminalFontSize ?? 14.0;
    _pendingSize = _baseSize;
  },
  onScaleUpdate: (d) {
    final next = (_baseSize * d.scale).clamp(8.0, 28.0);
    setState(() => _pendingSize = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final s = ref.read(settingsNotifierProvider).valueOrNull;
      if (s == null) return;
      ref.read(settingsNotifierProvider.notifier)
          .save(s.copyWith(terminalFontSize: next));
    });
  },
  child: TerminalView(terminal, fontSize: _pendingSize, ...),
)
```

`_pendingSize` est mis à jour immédiatement (retour visuel fluide) ; la persistance est throttlée à 300 ms pour ne pas spammer le disque.

### Anti-caractères résiduels (PTY sync)

Dans `_bindTerminal`, après le hook `terminal.onOutput` :

```dart
terminal.onResize = (cols, rows, pixelW, pixelH) {
  shell.resizePty(width: cols, height: rows);
};
```

Quand xterm recalcule la grille (nouveau fontSize → nouvelles dimensions), le shell reçoit le SIGWINCH immédiatement → pas de chevauchement de texte.

---

## 3. Copier

### Configuration xterm

```dart
final _controller = TerminalController();

TerminalView(
  terminal,
  controller: _controller,
  selectionMode: SelectionMode.line,
  // ...
)
```

`SelectionMode.line` : la sélection se fait ligne par ligne, le mode le plus utile dans un contexte SSH.

### Déclenchement et menu

`GestureDetector` wrappant `TerminalView` :

```dart
onLongPressEnd: (d) async {
  // terminal.selectedText est le getter xterm 4.x pour le texte actuellement sélectionné.
  // Si l'API n'expose pas selectedText, dériver depuis _controller.selection + terminal.buffer.
  final selected = terminal.selectedText?.trim();
  final clip = await Clipboard.getData(Clipboard.kTextPlain);
  _showContextMenu(
    position: d.globalPosition,
    selectedText: selected?.isEmpty == true ? null : selected,
    clipText: clip?.text,
  );
},
```

### Menu contextuel

`conn` est résolu via `ref.read(sshNotifierProvider(sessionId)).valueOrNull`.

```dart
void _showContextMenu({required Offset position, String? selectedText, String? clipText}) {
  final conn = ref.read(sshNotifierProvider(sessionId)).valueOrNull;
  final items = [
    if (selectedText != null)
      ContextMenuButtonItem(label: 'Copier', onPressed: () {
        Clipboard.setData(ClipboardData(text: selectedText));
        _controller.clearSelection();
        _contextMenuController.remove();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Copié'), duration: Duration(seconds: 1)));
      }),
    if (clipText != null && clipText.isNotEmpty)
      ContextMenuButtonItem(label: 'Coller', onPressed: () {
        conn?.sendRaw(Uint8List.fromList(utf8.encode(clipText)));
        _contextMenuController.remove();
      }),
  ];
  if (items.isEmpty) return;
  _contextMenuController.show(
    context: context,
    contextMenuBuilder: (_) => AdaptiveTextSelectionToolbar.buttonItems(
      anchors: TextSelectionToolbarAnchors(primaryAnchor: position),
      buttonItems: items,
    ),
  );
}
```

**Note implémentation :** `_contextMenuController` est un `ContextMenuController()` déclaré dans l'état. Il doit être `.remove()`-é dans `dispose()` et à chaque nouveau `onLongPressEnd`.

### Matrice de comportement

| Long press | Sélection présente | Presse-papier non vide | Menu affiché |
|---|---|---|---|
| ✓ | oui | oui | Copier + Coller |
| ✓ | oui | non | Copier |
| ✓ | non | oui | Coller |
| ✓ | non | non | rien |

---

## 4. Coller — bouton barre clavier

`KeyboardToolbar._onTap(ToolbarButtonType.paste)` :

```dart
case ToolbarButtonType.paste:
  final clip = await Clipboard.getData(Clipboard.kTextPlain);
  final text = clip?.text;
  if (text != null && text.isNotEmpty) {
    ref.read(sshNotifierProvider(widget.sessionId)).whenData(
      (conn) => conn?.sendRaw(Uint8List.fromList(utf8.encode(text))),
    );
  }
```

---

## 5. Fichiers modifiés / créés

| Fichier | Action |
|---|---|
| `lib/data/models/settings.dart` | Ajouter `terminalFontSize` |
| `lib/data/models/toolbar_button.dart` | Ajouter `paste` à l'enum + label |
| `lib/domain/services/ansi_service.dart` | Ajouter cas `paste` → `Uint8List(0)` |
| `lib/presentation/screens/terminal_screen.dart` | `_TerminalView` → StatefulWidget, zoom, long press, menu contextuel, PTY resize |
| `lib/presentation/widgets/keyboard_toolbar.dart` | Gérer `paste` dans `_onTap` |

---

## 6. Hors périmètre (future amélioration B)

- Handles de sélection personnalisés (style iOS/Android natif)
- Boutons zoom `+` / `−` visibles dans l'UI
- `SelectionMode.character` avec drag fin
- Sélection rectangulaire (`SelectionMode.block`)
