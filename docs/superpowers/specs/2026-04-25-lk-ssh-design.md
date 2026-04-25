# LK-SSH — Design Spec
**Date :** 2026-04-25  
**Stack :** Flutter (Dart) · Android uniquement  
**Auteur :** lararchfr

---

## 1. Objectif

Application Android légère de gestion de connexions SSH avec snippets one-tap, terminal PTY complet et multi-sessions. Alternative gratuite et custom à Termius.

---

## 2. Périmètre v1

**Inclus :**
- Connexion SSH par clé ed25519 (pas de mot de passe)
- Liste de serveurs (< 10)
- Terminal PTY complet (VT100/ANSI, support vim/htop/tmux)
- Multi-sessions simultanées via onglets
- Snippets one-tap avec templates à variables `{var}` et catégories
- Double confirmation toggleable par snippet
- Deux modes de stockage de clé (A et D)
- Import de clé via ADB / file_picker

**Exclu v1 (axes v2) :**
- Sync cloud / backup
- Tunnel SSH / port forwarding
- Support clé RSA (ed25519 uniquement)
- Base de données (→ Isar en v2)
- Multi-onglets terminal par serveur (1 session active par serveur)

---

## 3. Architecture

### Approche : Layered + Riverpod

```
lib/
├── data/
│   ├── storage/          # JSON persistence + flutter_secure_storage
│   │   ├── json_storage.dart
│   │   └── secure_key_storage.dart
│   ├── ssh/              # dartssh2 client wrapper
│   │   ├── ssh_client.dart
│   │   └── ssh_session.dart
│   └── models/           # freezed — Server, Snippet, Category, Session, Settings
├── domain/
│   └── services/
│       ├── ssh_service.dart        # Result<T,E> pattern
│       ├── storage_service.dart
│       └── snippet_service.dart   # résolution templates {var}
├── presentation/
│   ├── screens/
│   │   ├── server_list_screen.dart
│   │   ├── terminal_screen.dart
│   │   ├── snippet_editor_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/
│   │   ├── snippet_panel.dart      # panel glissable bas
│   │   ├── snippet_chip.dart       # chip one-tap
│   │   ├── variable_dialog.dart    # saisie variables {var}
│   │   └── confirm_bottom_sheet.dart
│   └── providers/
│       ├── servers_provider.dart
│       ├── sessions_provider.dart
│       ├── ssh_provider.dart       # family(sessionId)
│       ├── terminal_provider.dart  # family(sessionId)
│       ├── secure_key_provider.dart
│       └── settings_provider.dart
└── main.dart
```

### Extensibilité prévue (hooks v2)
- `StorageService` abstrait derrière une interface → swap JSON → Isar sans toucher les providers
- `SSHAuthStrategy` interface → ajout clé RSA, agent SSH, certificats sans refacto
- `SnippetTemplate` extensible → ajout types variables (liste déroulante, boolean) sans casser l'existant
- `SessionManager` découplé → multi-onglets par serveur possible sans réécriture

---

## 4. Packages

| Package | Version min | Rôle |
|---|---|---|
| `dartssh2` | ^2.0.0 | Client SSH + allocation PTY |
| `xterm` | ^4.0.0 | Rendu terminal VT100/ANSI |
| `flutter_secure_storage` | ^9.0.0 | Stockage clé (mode A) |
| `flutter_riverpod` | ^2.0.0 | State management |
| `riverpod_annotation` | ^2.0.0 | Code generation providers |
| `freezed` | ^2.0.0 | Models immuables |
| `freezed_annotation` | ^2.0.0 | Annotations freezed |
| `json_serializable` | ^6.0.0 | Sérialisation JSON |
| `cryptography` | ^2.0.0 | argon2id (mode D passphrase) |
| `file_picker` | ^8.0.0 | Import clé via ADB |
| `build_runner` | ^2.0.0 | Code generation |

---

## 5. Sécurité

### Mode A — flutter_secure_storage
```
clé ed25519 brute → EncryptedSharedPreferences
                    (chiffré Android Keystore AES-256)
déchiffrement     → RAM uniquement pendant session SSH active
```

### Mode D — Mode A + passphrase argon2id
```
clé ed25519 brute → argon2id(passphrase utilisateur)
                  → EncryptedSharedPreferences
déchiffrement     → argon2id(passphrase saisie à l'ouverture)
                  → RAM session uniquement
```

### Règles non négociables dans le code
- La clé privée ne transit jamais dans un log, un état Riverpod partagé ou un widget
- Objet `SecureKey` : efface les bytes (`zeroise`) après usage
- Aucune clé privée dans les models `freezed` sérialisés en JSON
- Timeout de session configurable (déconnexion auto)
- Pas de clipboard automatique sur commandes contenant des secrets
- Aucun `dynamic` dans le code — typage strict partout
- `dart analyze --fatal-infos` — zéro warning toléré

---

## 6. Navigation & Écrans

### Flux principal
```
ServerListScreen
  └─ tap serveur → connexion SSH → TerminalScreen(sessionId)
                                        ├─ onglets sessions [prod] [vps] [+]
                                        ├─ xterm widget (PTY)
                                        └─ SnippetPanel (glissable)

ServerListScreen [+] → ServerFormScreen (création)
ServerListScreen [⚙] → SettingsScreen
TerminalScreen chip  → VariableDialog (si {var})
                     → ConfirmBottomSheet (si double_confirm=true)
```

### Maquettes TUI

**ServerListScreen**
```
┌─────────────────────────────┐
│ LK-SSH              [+] [⚙] │
├─────────────────────────────┤
│ > prod-server-01            │
│   192.168.1.10 · root       │
├─────────────────────────────┤
│ > vps-perso                 │
│   51.x.x.x · admin          │
└─────────────────────────────┘
```

**TerminalScreen**
```
┌─────────────────────────────┐
│ [prod●] [vps] [nas] [+] [⚙]│
├─────────────────────────────┤
│ root@prod:~$ █              │
│                             │
│                             │
├─────────────────────────────┤
│ [System] [Docker] [Git]     │
│ ┌──────────┐ ┌───────────┐  │
│ │restart   │ │tail log   │  │
│ │nginx     │ │{lines}    │  │
│ └──────────┘ └───────────┘  │
│ ┌──────────┐ ┌───────────┐  │
│ │⚠ reboot  │ │df -h      │  │
│ └──────────┘ └───────────┘  │
└─────────────────────────────┘
```

**VariableDialog**
```
┌──────────────────────┐
│ tail error.log       │
│                      │
│ lines: [______]      │
│                      │
│   [Annuler] [Envoyer]│
└──────────────────────┘
```

**ConfirmBottomSheet**
```
╔═════════════════════════════╗
║  ⚠ Confirmer ?              ║
║  reboot                     ║
║  [Annuler]    [Exécuter]    ║
╚═════════════════════════════╝
```

**SettingsScreen**
```
┌─────────────────────────────┐
│ ← Paramètres                │
├─────────────────────────────┤
│ Stockage clé SSH            │
│  ○ Mode A — Secure Storage  │
│  ● Mode D — + Passphrase    │
├─────────────────────────────┤
│ Clé privée                  │
│  [Importer via fichier]     │
│  ✓ ed25519 chargée          │
├─────────────────────────────┤
│ Timeout session : [5 min ▾] │
│ Thème : [Sombre ▾]          │
└─────────────────────────────┘
```

---

## 7. Providers Riverpod

```
StorageProvider          SecureKeyProvider
(JSON servers/snippets)  (clé privée, mode A ou D)
        │                        │
        ▼                        ▼
  ServersProvider          SSHProvider(sessionId)     ← family
  (liste serveurs)    (connexion active, stream PTY)
        │                        │
        └──────────┬─────────────┘
                   ▼
          TerminalScreen
          (xterm ← stream PTY)    terminalProvider(sessionId) ← family
          (SnippetPanel ← ServersProvider)

sessionsProvider → NotifierProvider<List<Session>>  (registre global)
settingsProvider → NotifierProvider<Settings>
```

---

## 8. Flux snippets one-tap

```
tap chip
  │
  ├─ variables présentes ? → VariableDialog → résolution template
  │
  ├─ double_confirm=true ? → ConfirmBottomSheet
  │
  └─ SSHProvider(sessionId).send(command)
       └─ stream PTY → terminalProvider(sessionId) → xterm widget
```

---

## 9. Gestion d'erreurs

| Situation | Comportement |
|---|---|
| Connexion SSH échouée | Banner rouge inline (pas de dialog bloquant) |
| Timeout session | Déconnexion propre + onglet marqué [✗] |
| Commande stderr | Affiché dans xterm en rouge ANSI |
| Clé invalide / absente | Redirect SettingsScreen + message explicite |
| Fichier JSON corrompu | Reset données + log d'erreur (pas de crash) |

---

## 10. Qualité & Tests

- `Result<T, E>` pattern sur tous les appels SSH/storage
- Tests unitaires obligatoires : `SSHService`, `StorageService`, `SnippetService`, parsing `{var}`
- `dart analyze --fatal-infos` en CI
- Aucun `dynamic`, typage strict
- Models `freezed` — immutabilité garantie
