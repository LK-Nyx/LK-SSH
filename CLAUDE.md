# LK-SSH — Contexte pour Claude Code

## Lire en premier

La documentation technique complète se trouve dans [`docs/TECHNICAL.md`](docs/TECHNICAL.md).  
**Lis ce fichier avant de toucher au code.** Il couvre l'architecture, tous les modèles, les providers, les flux SSH, le système de snippets, et les décisions de conception.

---

## Ce qu'est ce projet

Application Android Flutter de gestion de sessions SSH. Terminal complet avec :
- Zoom pinch, copier-coller sélection
- Barre de touches clavier personnalisable (Ctrl, Alt, flèches, F1–F12, password…)
- Système de snippets avec templates `{variable}`, catégories, mode édition, confirmation
- Deux modes de stockage de clé SSH (brut FlutterSecureStorage / AES-GCM + Argon2id)

**Stack :** Flutter 3.19+ · Dart 3.3+ · Riverpod 2 (riverpod_annotation) · Freezed · dartssh2 · xterm

---

## Règles impératives

### Modèles Freezed
Tous les modèles (`Snippet`, `Category`, `Server`, `Session`, `Settings`, `ToolbarButton`) sont générés par Freezed + json_serializable.  
Après toute modification d'un fichier `*.freezed.dart` ou d'un modèle annoté `@freezed` :

```bash
dart run build_runner build --delete-conflicting-outputs
```

Ne jamais éditer les fichiers `*.g.dart` ou `*.freezed.dart` à la main.

### Providers Riverpod
- Les providers annotés `@riverpod` sont dans `lib/presentation/providers/`
- Toujours utiliser `ref.watch` en lecture réactive, `ref.read` pour les actions one-shot
- Les notifiers persistent dans `JsonStorageService` via `IStorageService`
- `sessionsNotifierProvider` est **en mémoire uniquement** (pas de persistance)

### Providers family avec autoDispose
`sshNotifierProvider(sessionId)` et `terminalProvider(sessionId)` utilisent `autoDispose: false` explicitement — ne pas changer, sinon les sessions SSH se coupent lors d'un rebuild.

### Performance terminal
L'architecture `isKeyboardAnimatingProvider` + `RepaintBoundary` est **critique** pour les 60fps.  
Voir section "Architecture du terminal" dans `docs/TECHNICAL.md`.  
Ne jamais appeler `terminal.resize()` pendant l'animation du clavier.

### Sécurité
- Ne jamais logger les clés SSH ou mots de passe (même en debug)
- `SecureKey` auto-zéroïse sa mémoire à la libération — ne pas copier la liste brute
- `FlutterSecureStorage` pour tout secret

---

## Patterns à suivre

### Ajouter un champ à un modèle
1. Éditer `lib/data/models/<model>.dart` — annoter `@Default(valeur)` si optionnel
2. `dart run build_runner build --delete-conflicting-outputs`
3. Mettre à jour `IStorageService` + `JsonStorageService` si le champ doit être persisté
4. Mettre à jour les providers/notifiers concernés
5. Mettre à jour les widgets qui affichent ou modifient ce champ

### Ajouter un provider
1. Créer `lib/presentation/providers/<nom>_provider.dart`
2. Annoter avec `@riverpod` ou `@Riverpod(keepAlive: true)` selon besoin
3. `dart run build_runner build --delete-conflicting-outputs`
4. Importer et utiliser via `ref.watch(<nom>Provider)`

### Ajouter un écran
1. Créer `lib/presentation/screens/<nom>_screen.dart`
2. Utiliser `ConsumerStatefulWidget` si l'écran a un état local + Riverpod
3. Naviguer via `Navigator.push(context, MaterialPageRoute(builder: (_) => NomScreen()))`

### Exécuter un snippet
Voir `SnippetPanel._executeSnippet()` :
1. Extraire les variables `{var}` via `SnippetService.extractVariables()`
2. Afficher `VariableDialog` si nécessaire
3. Résoudre via `SnippetService.resolve()`
4. Si `requireConfirm`, afficher `ConfirmBottomSheet`
5. `autoExecute ? conn.sendCommand(cmd) : conn.sendRaw(Uint8List.fromList(utf8.encode(cmd)))`

---

## Structure des répertoires clés

```
lib/
├── core/                    # Result<T,E>, AppError, SecureKey
├── data/
│   ├── models/              # Freezed models (Snippet, Category, Server, Session, Settings)
│   ├── storage/             # JsonStorageService, DebugLogService, DiagnosticRunner
│   └── ssh/                 # ISecureKeyStorage, Mode A (brut), Mode D (AES-GCM+Argon2id)
├── domain/services/         # SshService, SnippetService, AnsiService
└── presentation/
    ├── providers/            # Tous les providers Riverpod
    ├── screens/              # Écrans Flutter
    └── widgets/              # Widgets réutilisables
```

---

## Commandes utiles

```bash
# Générer le code Freezed/Riverpod après modification des modèles ou providers annotés
dart run build_runner build --delete-conflicting-outputs

# Builder l'APK debug
flutter build apk --debug

# Lancer sur device connecté
flutter run

# Analyser le code
flutter analyze
```

---

## Pièges connus

| Piège | Cause | Solution |
|---|---|---|
| `autoDispose` sur `terminalProvider` | xterm se réinitialise à chaque rebuild | Garder `keepAlive: true` / `autoDispose: false` |
| `terminal.resize()` pendant animation clavier | 60 appels/s → freeze 3fps | `isKeyboardAnimatingProvider` → `autoResize: false` |
| `resizeToAvoidBottomInset: false` | PTY croit avoir 50+ lignes → output masqué | Garder `true`, gérer la hauteur via Column + Expanded |
| Éditer `*.freezed.dart` manuellement | Écrasé au prochain `build_runner` | Toujours éditer le fichier source annoté |
| `const` sur une liste qui appelle un constructeur Freezed | `const_initialized_with_non_constant_value` | Utiliser `final` |
| `ref.read` dans `build()` | Pas réactif | Utiliser `ref.watch` en build, `ref.read` en callbacks |

---

## Liens rapides

- [Documentation technique complète](docs/TECHNICAL.md)
- [Specs clavier/toolbar](docs/superpowers/specs/2026-04-26-keyboard-toolbar-design.md)
- [Plan implémentation clavier](docs/superpowers/plans/2026-04-26-keyboard-toolbar.md)
- [Specs zoom/copier-coller](docs/superpowers/specs/2026-04-26-terminal-copy-paste-zoom-design.md)
- [Plan implémentation zoom](docs/superpowers/plans/2026-04-26-terminal-copy-paste-zoom.md)
