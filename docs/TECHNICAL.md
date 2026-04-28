# LK-SSH — Documentation Technique

## Vue d'ensemble

LK-SSH est une application Android (Flutter) de gestion de sessions SSH. Elle propose un terminal complet avec zoom pinch, copier-coller, un système de snippets avec templates de variables, une barre de touches clavier personnalisable, et deux modes de stockage de clé SSH (brut / chiffré Argon2id + AES-GCM).

**Stack technique :** Flutter 3.19+ / Dart 3.3+ · Riverpod 2 (+ riverpod_annotation) · Freezed · dartssh2 · xterm · flutter_secure_storage · cryptography · JSON sur filesystem

---

## Structure des répertoires

```
lib/
├── core/
│   ├── errors.dart              # Classes d'erreur scellées (AppError hierarchy)
│   ├── result.dart              # Type union Result<T, E> (Ok / Err)
│   └── secure_key.dart          # Wrapper mémoire pour clé SSH (auto-zeroise)
│
├── data/
│   ├── models/                  # Freezed + JSON-serializable
│   │   ├── category.dart        # Category {id, label}
│   │   ├── server.dart          # Server {id, label, host, port, username}
│   │   ├── session.dart         # Session {id, serverId, label, status}
│   │   ├── settings.dart        # Settings {keyStorageMode, theme, toolbarButtons, ...}
│   │   ├── snippet.dart         # Snippet {id, label, command, categoryId, requireConfirm, autoExecute}
│   │   └── toolbar_button.dart  # ToolbarButton {type, label?}
│   │
│   ├── storage/
│   │   ├── i_storage_service.dart      # Interface CRUD (servers, snippets, categories, settings)
│   │   ├── json_storage_service.dart   # Implémentation JSON filesystem
│   │   ├── debug_log_service.dart      # Singleton de log fichier (opt-in)
│   │   └── diagnostic_runner.dart      # Runner de tests automatisés (zoom, flèches, commandes)
│   │
│   └── ssh/
│       ├── i_secure_key_storage.dart   # Interface storeKey / loadKey / deleteKey / hasKey
│       ├── secure_key_storage_a.dart   # Mode A : clé brute base64 (FlutterSecureStorage)
│       ├── secure_key_storage_d.dart   # Mode D : AES-GCM + Argon2id
│       └── toolbar_password_storage.dart # Stockage mot de passe barre clavier
│
├── domain/
│   └── services/
│       ├── ssh_service.dart     # SSHService, SshConnection, DefaultSshClientFactory
│       ├── snippet_service.dart # Extraction et résolution de variables {var}
│       └── ansi_service.dart    # Séquences ANSI, modificateurs sticky (Ctrl/Alt/Shift)
│
└── presentation/
    ├── providers/
    │   ├── storage_provider.dart          # storageProvider (async, singleton)
    │   ├── secure_key_provider.dart       # secureKeyStorageProvider (A ou D selon settings)
    │   ├── settings_provider.dart         # settingsNotifierProvider
    │   ├── servers_provider.dart          # serversNotifierProvider
    │   ├── sessions_provider.dart         # sessionsNotifierProvider (état en mémoire)
    │   ├── terminal_provider.dart         # terminalProvider(sessionId) (autoDispose désactivé)
    │   ├── ssh_provider.dart              # sshNotifierProvider(sessionId) (family, autoDispose)
    │   ├── snippets_provider.dart         # snippetsNotifierProvider + categoriesNotifierProvider
    │   ├── keyboard_toolbar_provider.dart # keyboardToolbarProvider(sessionId)
    │   ├── keyboard_animation_provider.dart # isKeyboardAnimatingProvider
    │   └── diagnostic_provider.dart       # diagnosticFontSizeProvider
    │
    ├── screens/
    │   ├── server_list_screen.dart        # Écran d'accueil, liste des serveurs
    │   ├── server_form_screen.dart        # Formulaire ajout/édition serveur
    │   ├── terminal_screen.dart           # Écran principal (terminal + tabs + barre)
    │   ├── settings_screen.dart           # Paramètres (clé, debug, toolbar)
    │   ├── snippet_editor_screen.dart     # Formulaire snippet (label, commande, catégorie)
    │   └── category_editor_screen.dart    # Gestion catégories (rename, reorder, delete)
    │
    └── widgets/
        ├── keyboard_toolbar.dart    # Barre de touches (scroll, edit mode, reorder)
        ├── snippet_panel.dart       # Panneau snippets (onglets catégories + chips)
        ├── snippet_chip.dart        # Chip individuel (normal / edit mode)
        ├── confirm_bottom_sheet.dart # Confirmation avant envoi snippet dangereux
        └── variable_dialog.dart     # Résolution de variables {var} dans un snippet
```

---

## Modèles de données

### `Snippet`
```dart
Snippet({
  required String id,           // UUID v4
  required String label,        // Libellé affiché sur le chip
  required String command,      // Template shell — supporte {variable}
  required String categoryId,   // Référence Category.id
  @Default(false) bool requireConfirm,  // Si true : sheet de confirmation avant envoi
  @Default(true)  bool autoExecute,    // Si true : sendCommand (avec \n) ; false : sendRaw (sans \n)
})
```

Signalisation visuelle des chips :
- `requireConfirm: true` → bordure orange + icône `warning_amber`
- `autoExecute: false` → bordure bleue + icône `edit_note` (snippet "variable")

### `Category`
```dart
Category({ required String id, required String label })
```
Défauts (si fichier vide) : `system`, `docker`, `git`.

### `Server`
```dart
Server({
  required String id,
  required String label,
  required String host,
  @Default(22) int port,
  required String username,
})
```

### `Session`
```dart
enum SessionStatus { connecting, connected, disconnected, error }
Session({ required String id, required String serverId, required String label, SessionStatus status })
```
Les sessions ne sont **pas persistées** — elles vivent en mémoire dans `sessionsNotifierProvider`.

### `Settings`
```dart
Settings({
  KeyStorageMode keyStorageMode,   // secureStorage (Mode A) | passphraseProtected (Mode D)
  int sessionTimeoutMinutes,       // défaut 5
  AppTheme theme,                  // dark | light
  bool verboseLogging,             // logs détaillés dans le terminal
  List<ToolbarButton> toolbarButtons, // boutons personnalisés
  bool fixedNavSection,            // section navigation fixée à gauche
  double terminalFontSize,         // taille de police (8–28px)
  bool fileDebugMode,              // active DebugLogService
})
```

### `ToolbarButton`
```dart
enum ToolbarButtonType {
  ctrl, alt, shift, esc, tab,
  arrowUp, arrowDown, arrowLeft, arrowRight,
  home, end, pageUp, pageDown, del,
  f1..f12, password, paste,
}
ToolbarButton({ required ToolbarButtonType type, String? label })
```

---

## Stockage (Persistence)

### Fichiers JSON — `{appDocDir}/lk_ssh_data/`
| Fichier              | Contenu                         |
|----------------------|---------------------------------|
| `servers.json`       | `List<Server>`                  |
| `snippets.json`      | `List<Snippet>`                 |
| `categories.json`    | `List<Category>`                |
| `settings.json`      | `Settings`                      |

Interface `IStorageService` — méthodes : `loadServers`, `saveServers`, `loadSnippets`, `saveSnippets`, `loadCategories`, `saveCategories`, `loadSettings`, `saveSettings`. Toutes retournent `Result<T, StorageError>`.

### Stockage sécurisé — `FlutterSecureStorage`
| Clé                    | Contenu                                           | Classe              |
|------------------------|---------------------------------------------------|---------------------|
| `ssh_private_key_b64`  | Clé SSH brute en base64 (Mode A)                 | `SecureKeyStorageA` |
| `ssh_key_enc_d`        | Clé SSH chiffrée AES-GCM (Mode D)                | `SecureKeyStorageD` |
| `ssh_key_salt_d`       | Salt Argon2id 32 bytes (Mode D)                  | `SecureKeyStorageD` |
| `toolbar_password`     | Mot de passe du bouton 🔑                         | `ToolbarPasswordStorage` |

**Mode D (chiffrement) :** Argon2id (memory=65536, parallelism=2, iterations=3, hashLength=32) → clé AES-GCM 256 bits → chiffrement de la clé SSH brute.

---

## Providers Riverpod

Tous les providers d'état utilisent `@riverpod` (code généré dans `.g.dart`). Les providers family sont identifiés par `sessionId: String`.

### Providers globaux
| Provider | Type | Description |
|----------|------|-------------|
| `storageProvider` | `Future<IStorageService>` | Singleton JsonStorage |
| `secureKeyStorageProvider` | `ISecureKeyStorage` | Mode A ou D selon settings |
| `settingsNotifierProvider` | `AsyncNotifier<Settings>` | CRUD paramètres |
| `serversNotifierProvider` | `AsyncNotifier<List<Server>>` | CRUD serveurs |
| `snippetsNotifierProvider` | `AsyncNotifier<List<Snippet>>` | CRUD + reorder snippets |
| `categoriesNotifierProvider` | `AsyncNotifier<List<Category>>` | CRUD + reorder + rename catégories |
| `sessionsNotifierProvider` | `Notifier<List<Session>>` | État mémoire des onglets |
| `isKeyboardAnimatingProvider` | `StateProvider<bool>` | Animation clavier en cours |
| `diagnosticFontSizeProvider` | `StateProvider<double?>` | Taille de police pour diagnostic |

### Providers family (par session)
| Provider | Type | Description |
|----------|------|-------------|
| `sshNotifierProvider(sessionId)` | `AsyncNotifier<SshConnection?>` | Connexion SSH (autoDispose) |
| `terminalProvider(sessionId)` | `Terminal` | Instance xterm |
| `keyboardToolbarProvider(sessionId)` | `Notifier<KeyboardToolbarState>` | Mod actif + edit mode |

**Attention autoDispose :** `sshNotifierProvider` utilise `@riverpod` qui génère un provider `autoDispose` par défaut. `_TerminalViewState.build()` contient `ref.watch(sshNotifierProvider(sessionId))` pour maintenir le provider vivant tant que le terminal est monté.

---

## Connexion SSH (`SshService` + `SshConnection`)

### Flux de connexion
```
_connect(sessionId, server)
  → secureKeyStorageProvider.loadKey()   (déchiffre si Mode D)
  → sshNotifierProvider.connect(server, key)
      → SSHService.connect()
          → SSHSocket.connect(host, port, timeout: 15s)
          → SSHClient.authenticate(timeout: 20s, identities: [key])
          → SshConnection(client, server)
  → _bindTerminal(sessionId, conn)
      → conn.openShell(width: 120, height: 40)
      → shell.stdout → terminal.write()
      → shell.stderr → terminal.write()
      → terminal.onOutput → AnsiService.applyMod → shell.write()
      → terminal.onResize → debounce(50ms) → shell.resizeTerminal()
```

### `SshConnection`
```dart
void sendCommand(String command)  // bytes + '\n'
void sendRaw(Uint8List bytes)     // bytes bruts (snippets autoExecute: false)
Future<Result<SSHSession, AppError>> openShell({int width, int height})
void close()
```

### Gestion du resize PTY
`terminal.onResize` est appelé par xterm quand le terminal change de taille. Un debounce de 50ms évite les resize répétés. Pendant ce délai, `terminal.reflowEnabled = false` pour éviter les artefacts de reflow.

---

## Terminal (`_TerminalView` dans `terminal_screen.dart`)

### Zoom pinch
- `Listener` (non-participatif à l'arène de gestes) capte `onPointerDown/Move/Up/Cancel`
- 2 pointeurs actifs → calcul de la distance → `_pendingSize` interpolé (clamped 8–28px)
- Debounce 300ms → sauvegarde dans settings (`terminalFontSize`)
- Pendant le zoom : `autoResize: false` (pas de `terminal.resize()` par frame)

### `autoResize` — règle critique
`TerminalView(autoResize: ...)` contrôle si xterm appelle `terminal.resize()` lors de chaque `performLayout`. Il est désactivé dans deux cas :
1. **Zoom pinch** : `_pinchStartDistance != null`
2. **Animation clavier** : `isKeyboardAnimatingProvider == true`

Dans les deux cas : zéro `terminal.resize()` par frame → zéro `notifyListeners()` par frame → zéro repaint du terminal par frame → fluidité 60fps.

### Détection animation clavier
`_TerminalBottomBarState.didChangeDependencies()` lit `MediaQuery.viewInsetsOf(context).bottom`. Tout changement déclenche via `postFrameCallback` :
1. `isKeyboardAnimatingProvider = true` (immédiat)
2. Timer 350ms → `isKeyboardAnimatingProvider = false`

`_TerminalViewState.initState()` préempte `isKeyboardAnimating = true` dès le 1er frame (le clavier s'ouvre automatiquement via `autofocus: true`).

### RepaintBoundary
`_TerminalView` est wrappé dans `RepaintBoundary` dans `TerminalScreen.build()`. Les repaints de `_TerminalBottomBar` (rebuild par frame pendant l'animation) n'affectent pas le layer du terminal.

### Copier / Coller
`onSecondaryTapDown` → `ContextMenuController.show()` avec :
- **Copier** : si `_controller.selection != null` → `Clipboard.setData`
- **Coller** : si presse-papiers non vide → `conn.sendRaw(utf8.encode(clipText))`

---

## Barre de touches (`KeyboardToolbar`)

### Modificateurs sticky
`keyboardToolbarProvider(sessionId).activeMod` stocke le modificateur actif (`ctrl`, `alt`, `shift` ou `null`). `terminal.onOutput` applique le mod via `AnsiService.applyMod(data, mod)` puis le reset immédiatement.

### Mode édition
Long press sur la barre → `toggleEditMode()`. En mode édition :
- `ReorderableListView(scrollDirection: Axis.horizontal)` remplace `ListView`
- Bouton X rouge sur chaque touche → suppression
- Bouton + → ajoute une touche disponible
- Drag pour réordonner (via `ValueKey(btn.type)`)

### Section navigation fixe (`fixedNavSection`)
Si activée et hors édition : les touches `ctrl, alt, shift, esc, tab, arrowUp/Down/Left/Right` sont épinglées à gauche (non-scrollables). Les autres sont dans `ListView` scrollable à droite.

---

## Snippets

### Flux d'exécution
```
_executeSnippet(snippet)
  → extractVariables(snippet.command)  [regex \{(\w+)\}]
  → VariableDialog (si variables)
  → SnippetService.resolve(template, vars)
  → ConfirmBottomSheet (si requireConfirm)
  → if autoExecute: conn.sendCommand(command)   ← avec \n
    else:            conn.sendRaw(utf8.encode(command))  ← sans \n
```

### Mode édition snippets
Long press sur un chip dans `SnippetPanel` → `_editMode = true`.

En mode édition (`_buildEditableList`) :
- `ReorderableListView(scrollDirection: Axis.horizontal, buildDefaultDragHandles: false)`
- Chaque chip wrappé dans `ReorderableDragStartListener` (long press → drag)
- `SnippetChip(editMode: true)` → X rouge en haut à droite
- Tap corps du chip → `SnippetEditorScreen`
- Tap X → `snippetsNotifierProvider.delete(id)`
- Bouton ✓ dans la barre catégories → quitte le mode édition

### Réordonnancement
`SnippetsNotifier.reorder(oldIndex, newIndex, categoryId)` :
1. Extrait les snippets de la catégorie
2. Réordonne en place
3. Reconstruit la liste globale en remplaçant les snippets de la catégorie à leurs positions d'origine

### Gestion des catégories (`CategoryEditorScreen`)
Accessible via bouton `tune` dans la barre des onglets catégories.
- `ReorderableListView.builder` (vertical) — drag par `leading: Icon(drag_handle)`
- Rename : dialog `TextEditingController`
- Delete : dialog de confirmation (indique le nombre de snippets associés) — supprime aussi les snippets via `deleteByCategory`
- Ajout : dialog + `Category(id: Uuid().v4(), label: ...)`

---

## Services de domaine

### `AnsiService`
```dart
static Uint8List sequenceFor(ToolbarButtonType type)
// Exemples de séquences émises :
// arrowUp    → \x1b[A     arrowDown  → \x1b[B
// arrowRight → \x1b[C     arrowLeft  → \x1b[D
// esc        → \x1b       tab        → \t
// home       → \x1b[H     end        → \x1b[F
// pageUp     → \x1b[5~    pageDown   → \x1b[6~
// del        → \x1b[3~
// F1         → \x1bOP     F2         → \x1bOQ
// F3         → \x1bOR     F4         → \x1bOS
// F5         → \x1b[15~   F6         → \x1b[17~
// F7         → \x1b[18~   F8         → \x1b[19~
// F9         → \x1b[20~   F10        → \x1b[21~
// F11        → \x1b[23~   F12        → \x1b[24~

static Uint8List applyMod(String data, StickyMod? mod)
// ctrl  : for each char c → (c.codeUnitAt(0) & 0x1F)
// alt   : prepend \x1b
// shift : data.toUpperCase()
```

### `SnippetService`
```dart
static List<String> extractVariables(String template)
// Regex : \{(\w+)\} → liste dédupliquée ordonnée

static Result<String, String> resolve(String template, Map<String, String> variables)
// Replace all {key} par variables[key], Err si variable manquante
```

---

## Diagnostic (`DiagnosticRunner`)

Accessible via bouton 🔬 dans `SnippetPanel` si `fileDebugMode: true`.

Le runner pilote de **vrais changements de layout Flutter** via `diagnosticFontSizeProvider` (qui se substitue à `_pendingSize` dans `_TerminalViewState`). Cela déclenche le vrai chemin `TerminalView.performLayout()` → `_resizeTerminalIfNeeded()` → `terminal.resize()` → `onResize` callback.

**Phases du test :**
| Phase | Description | Plage | Délais |
|-------|-------------|-------|--------|
| Flèches | Envoie UP/DOWN/LEFT/RIGHT | — | 200ms |
| Commandes | ls, clear, notify-send, sudo ls | — | 900ms |
| A | Zoom modéré avec hésitations | 14–22px | 18–25ms |
| B | Zoom MAX + oscillations au max | 14–28px | 15–18ms |
| C | Dézoom MIN + oscillations au min | 8–14px | 15–18ms |
| D | Swing brutal MAX→MIN→MAX | 8–28px | 15ms |
| E | Séquence chaotique (grands sauts) | 8–28px | 15–18ms |
| F | Oscillations 8↔28 (stress pur, 1 frame) | 8/28px | 16ms |

Après chaque phase : `_dumpVisible(terminal, label)` logue le buffer visible en texte + hex dans `DebugLogService`.

---

## Debug Logging (`DebugLogService`)

Singleton activé via `Settings.fileDebugMode`. Écrit dans :
```
/storage/emulated/0/Android/data/dev.lararchfr.lk_ssh/files/lk-ssh-debug.log
```

Tags utilisés :
| Tag | Émetteur | Données |
|-----|----------|---------|
| `PTY` | `_bindTerminal` | onResize cols×rows, resizeTerminal, postFrameSync |
| `SNIPPET` | `_SnippetPanelState` | command, autoExecute, état connexion |
| `TOOLBAR` | `_KeyboardToolbarState` | type bouton, bytes séquence, état connexion |
| `DIAG` | `DiagnosticRunner` | phases, dump buffer |

---

## Points d'attention / Décisions d'architecture

### autoDispose et `keep-alive`
`@riverpod` génère des providers `autoDispose`. Si aucun listener ne `watch` le provider, il est détruit. `_TerminalViewState.build()` appelle `ref.watch(sshNotifierProvider(sessionId))` uniquement pour maintenir la connexion SSH vivante pendant toute la durée de vie du widget.

### `reflowEnabled` et artefacts de zoom
xterm réordonne les lignes du buffer quand la largeur change (`terminal.resize()` avec `reflowEnabled: true`). Pour éviter les artefacts, `onResize` désactive immédiatement `reflowEnabled` et le réactive après le debounce PTY.

### Séparation layout / repaint
`RenderTerminal.performLayout()` est appelé à chaque frame pendant les animations (clavier, zoom). Ce n'est pas un problème de performance tant que `markNeedsPaint()` n'est pas déclenché. Les appels à `terminal.resize()` → `notifyListeners()` → `setState()` → repaint sont la vraie cause des 3fps.

### Famille de providers SSH
`sshNotifierProvider` est un provider family (`sessionId` comme clé). Chaque onglet de session a sa propre instance de connexion SSH isolée.

---

## Dépendances clés

| Package | Version | Rôle |
|---------|---------|------|
| `dartssh2` | ^2.9.0 | Protocole SSH (client, auth par clé, PTY) |
| `xterm` | ^4.0.0 | Émulateur de terminal (buffer, reflow, cursor) |
| `flutter_riverpod` | ^2.5.1 | État réactif |
| `riverpod_annotation` | ^2.3.5 | Code gen providers |
| `freezed_annotation` | ^2.4.1 | Data classes immutables |
| `json_annotation` | ^4.9.0 | Sérialisation JSON |
| `flutter_secure_storage` | ^9.2.2 | Stockage chiffré Android (EncryptedSharedPreferences) |
| `cryptography` | ^2.7.0 | Argon2id + AES-GCM (Mode D) |
| `file_picker` | ^8.1.2 | Import de clé PEM depuis fichier |
| `path_provider` | ^2.1.3 | Répertoire documents application |
| `uuid` | ^4.4.0 | Génération d'identifiants UUID v4 |

**Code generation :** `dart run build_runner build --delete-conflicting-outputs`  
Fichiers générés : `*.freezed.dart`, `*.g.dart` (ne pas modifier manuellement)

---

## Tests

Tests mocktail + fakes. Pas de tests UI/widget actuellement (smoke manuel sur device).

---

## Phase 1 — Auth multi-méthodes & host trust

Implémentée dans la branche `feat/p1-auth-host-trust`. Spec : [`docs/superpowers/specs/2026-04-27-auth-host-trust-design.md`](superpowers/specs/2026-04-27-auth-host-trust-design.md). Plan : [`docs/superpowers/plans/2026-04-27-auth-host-trust.md`](superpowers/plans/2026-04-27-auth-host-trust.md).

### Méthodes d'authentification

`Server.authMethod` (enum `AuthMethod`) choisit entre :
- **`key`** — clé SSH (référencée par `Server.keyId` qui pointe vers une `SshKey` du registre)
- **`password`** — mot de passe (avec opt-in `savePassword` pour le stocker via `IPasswordStorage`)
- **`keyboardInteractive`** — challenges/réponses (2FA, OTP) via `SSHUserInfoRequest`

Le `sshNotifier` lit `authMethod` et construit un `AuthCredentials` (sealed : `KeyCreds` / `PasswordCreds` / `InteractiveCreds`) que `SshClientFactory.connect()` consomme.

### Multi-keys

Modèle `SshKey { id, label, addedAt }` (Freezed). Métadonnées dans `ssh_keys.json`. Bytes (et passphrase éventuelle) dans :
- **Mode A** : `SshKeyRegistryA` — `FlutterSecureStorage` indexé par `key_<id>` / `pp_<id>`
- **Mode D** : `SshKeyRegistryD` — vault `key_vault.bin` chiffré en Argon2id (mêmes paramètres que le mode D legacy) + AES-GCM, contenu = `Map<keyId, {bytes_b64, passphrase}>`

Le provider `sshKeyRegistryProvider` est async et retourne le bon registry selon `KeyStorageMode`. En mode D, il lit la passphrase via `vaultPassphraseProvider` (in-memory, jamais persisté).

### Host trust (TOFU)

`HostKeyVerifier` :
- **1ère connexion** : auto-pin du fingerprint dans `known_hosts.json` (`Map<host:port, fingerprint>`)
- **Mismatch** : invoque `onMismatch` qui affiche `HostKeyMismatchSheet` ; le user choisit `reject` / `acceptOnce` / `acceptAndPin`

dartssh2 fournit le digest MD5 du host key (typedef `SSHHostkeyVerifyHandler`). On l'encode en base64 pour le storage.

### Boot & migration

`main.dart` orchestre :
1. Charge `Settings`. Si mode D ET (vault existe OU clé legacy mode D) → push `UnlockScreen`
2. User entre la passphrase, vérifiée contre le vault ou la clé legacy
3. `vaultPassphraseProvider.unlock(passphrase)` (in-memory)
4. Run `P1AuthMigration` :
   - Si flag `migrationP1Done` ou pas de clé legacy → no-op
   - Sinon : crée `SshKey "default"`, copie les bytes legacy via `ISshKeyRegistry.save`, retag les serveurs (`authMethod=key, keyId=default`), set le flag

### Prompts à la connexion

`sshNotifier` expose `Stream<AuthPromptRequest>` (sealed : `PasswordPromptRequest` / `KbInteractivePromptRequest` / `HostKeyMismatchRequest`, chacun avec son `Completer`). `terminal_screen` souscrit par sessionId et dispatche vers la bottom sheet correspondante. Au dispose, les Completers en attente sont résolus avec une valeur de cancel pour ne pas bloquer le `connect()` Future.

---

## Design System Foundation

Sous-projet implémenté sur la branche `feat/design-system-foundation`.
Spec : [`docs/superpowers/specs/2026-04-28-design-system-foundation-design.md`](superpowers/specs/2026-04-28-design-system-foundation-design.md).
Plan : [`docs/superpowers/plans/2026-04-28-design-system-foundation.md`](superpowers/plans/2026-04-28-design-system-foundation.md).

### Tokens

`lib/presentation/design/tokens/` — `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppBorders`, `AppMotion`. Direction "matrix raffiné" (canvas `#0A0A0A` + accent vert sage `#3FCB3F` + neon `#00FF41` réservé au focus glow). Police mono = JetBrains Mono (embarquée Regular + Bold), sans = system Roboto sur Android.

### Focus glow

Règle : le `border` reste la teinte calme et lisible (corail `#FF5C5C` en erreur, sage `#3FCB3F` en accent), le `glow` utilise la version neon de la même teinte. `AppColors.focusGlow(state)` retourne le `BoxShadow` paramétré par `FocusGlowState` (accent / error / warning / info). En erreur + focus, opacité poussée à 0.60 et blur 16 pour rester lisible.

### Primitives

`lib/presentation/design/widgets/` — `AppButton` (4 variantes × états dont loading), `AppTextField` (focus glow couleur-conditionné, mono toggle), `AppTile` (leading/trailing/badge/active marker), `AppCard` (header/body/footer slots), `AppSheet` + helper `showAppSheet`. Les écrans existants ne sont pas migrés vers ces primitives dans ce sous-projet — c'est l'objet des sous-projets ultérieurs.

### Theme

`AppTheme.dark()` (importé en `as ds` dans `main.dart` pour éviter le conflit avec l'enum `AppTheme { dark, light }` de `Settings`) produit un `ThemeData` Material 3 mappé sur les tokens. Les widgets Material existants restent dans le ton tant qu'ils ne sont pas migrés.

### Gallery debug

`Settings → Debug → Design Gallery` (visible uniquement en `kDebugMode`) liste toutes les primitives et leurs états pour validation visuelle sur device.
