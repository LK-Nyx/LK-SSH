# Keyboard Toolbar — Design Spec
Date: 2026-04-26

## Objectif

Ajouter une barre de touches spéciales scrollable et personnalisable entre le terminal et le SnippetPanel, inspirée de la bottom bar Termius. Permet d'envoyer des modificateurs sticky (Ctrl/Alt/Shift), des touches de navigation, des touches de fonction et le mot de passe stocké directement au shell SSH actif.

---

## 1. Modèle de données

### `ToolbarButtonType` (enum)
```
ctrl, alt, shift,
esc, tab,
arrowUp, arrowDown, arrowLeft, arrowRight,
home, end, pageUp, pageDown,
f1..f12,
password
```

### `ToolbarButton` (freezed, json_serializable)
```dart
ToolbarButton {
  ToolbarButtonType type,
  String? label,   // null = label par défaut selon le type
}
```

### Ajouts à `Settings`
- `toolbarButtons: List<ToolbarButton>` — ordre persisté, défaut usine ci-dessous
- `fixedNavSection: bool` — défaut `false`

**Défaut usine :**
`[ctrl, alt, shift, esc, tab, arrowUp, arrowDown, arrowLeft, arrowRight, home, end, pageUp, pageDown, password, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12]`

---

## 2. État & logique

### `KeyboardToolbarNotifier` (Riverpod, par sessionId)

État :
```dart
KeyboardToolbarState {
  StickyMod? activeMod,   // null | ctrl | alt | shift
  bool editMode,
}
```

**Sticky modifier :**
1. Tap sur Ctrl/Alt/Shift → `activeMod` basculé (retap = désactive)
2. Prochain char dans `terminal.onOutput` → transformation appliquée → `activeMod = null`
   - Ctrl : `charCode & 0x1F` → ex. C=`\x03`, D=`\x04`, Z=`\x1a`, L=`\x0c`
   - Alt  : `\x1b` + char
   - Shift : char.toUpperCase() (cas minoritaires non couverts par le clavier système)

**Séquences ANSI envoyées directement au shell :**
| Touche   | Séquence       |
|----------|----------------|
| ↑        | `\x1b[A`       |
| ↓        | `\x1b[B`       |
| →        | `\x1b[C`       |
| ←        | `\x1b[D`       |
| Home     | `\x1b[H`       |
| End      | `\x1b[F`       |
| PageUp   | `\x1b[5~`      |
| PageDown | `\x1b[6~`      |
| Esc      | `\x1b`         |
| Tab      | `\t`           |
| F1–F4    | `\x1bOP`–`\x1bOS` |
| F5–F12   | `\x1b[15~`–`\x1b[24~` |
| Password | contenu de `FlutterSecureStorage(key: 'toolbar_password')` + `\n` |

**Mode édition :**
- Long press sur la barre → `editMode = true`
- Long press à nouveau ou tap en dehors → `editMode = false` + sauvegarde dans Settings

---

## 3. Widget — `KeyboardToolbar`

Hauteur : **44px**. `ConsumerWidget`, reçoit `sessionId`.

### Mode normal
- `ListView` horizontal scrollable
- Si `fixedNavSection = true` : flèches (↑↓←→) + Esc + Tab épinglés à gauche, séparateur vertical `|`, reste scrollable à droite
- Boutons modificateurs actifs : fond `Color(0xFF00FF41)`, texte noir
- Bouton password : icône cadenas, n'affiche rien dans le terminal
- Style cohérent avec l'UI existante : fond `Color(0xFF1A1A1A)`, texte monospace

### Mode édition
- Fond `Color(0xFF252525)` pour différenciation visuelle
- Chaque bouton affiche une croix `×` tap-to-delete
- `ReorderableListView` horizontal pour le drag & drop
- Bouton `+` en fin de liste → `ModalBottomSheet` listant les types non présents
- Bouton "Réinitialiser" en fin → restaure le défaut usine

---

## 4. Intégration

### `terminal_screen.dart`

**Colonne dans `build` :**
```
_SessionTabBar      (40px)
TerminalView        (Expanded)
KeyboardToolbar     (44px)   ← nouveau
SnippetPanel        (116px)
```

**`_bindTerminal` modifié :**
`terminal.onOutput` est wrappé : avant d'envoyer au shell, consulte `KeyboardToolbarNotifier` pour appliquer le modificateur sticky actif et le réinitialiser.

```dart
terminal.onOutput = (data) {
  final mod = ref.read(keyboardToolbarProvider(sessionId)).activeMod;
  final bytes = applyMod(data, mod);   // fonction pure
  if (mod != null) ref.read(...notifier).clearMod();
  shell.write(bytes);
};
```

### `settings_screen.dart`

Nouveau champ texte masqué : **"Mot de passe (barre clavier)"** — écrit dans `FlutterSecureStorage` clé `toolbar_password`.
Nouveau toggle : **"Section navigation fixe"** (active `fixedNavSection`).
Nouveau bouton : **"Réinitialiser la barre clavier"** (restaure défaut usine dans Settings).

---

## 5. Hors périmètre

- Profils de barre multiples (feature C rejetée)
- Gestion du clavier système (HW keyboard Bluetooth)
- Macros multi-touches (Ctrl+Alt+Del, etc.)
