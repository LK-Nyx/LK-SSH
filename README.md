# LK-SSH

Application Android Flutter de gestion de sessions SSH. Alternative légère et personnalisable à Termius.

## Fonctionnalités

- Terminal PTY complet — VT100/ANSI, vim, htop, tmux
- Multi-sessions en onglets (plusieurs serveurs simultanément)
- Zoom pinch sur le terminal (8–28px, persisté)
- Copier / coller via menu contextuel
- **Snippets one-tap** — templates `{variable}`, catégories, réordonnables, mode édition
- **Barre de touches** personnalisable — Ctrl, Alt, flèches, F1–F12, password, paste
- Deux modes de stockage de clé SSH : Secure Storage (Mode A) ou AES-GCM + Argon2id (Mode D)
- Timeout d'inactivité configurable + keepalive SSH

## Stack

Flutter 3.19+ · Dart 3.3+ · Riverpod 2 · Freezed · dartssh2 · xterm

## Lancer le projet

```bash
# Cloner
git clone https://github.com/LK-Nyx/LK-SSH.git
cd LK-SSH

# Dépendances
flutter pub get

# Générer le code Freezed/Riverpod
dart run build_runner build --delete-conflicting-outputs

# Lancer sur device connecté
flutter run

# Build APK debug
flutter build apk --debug
```

## Contribuer

Lire **[CLAUDE.md](CLAUDE.md)** avant de toucher au code — il documente l'architecture complète, les règles impératives et les pièges connus.

```bash
# Avant chaque PR
flutter analyze --fatal-infos   # doit retourner "No issues found"
flutter test                     # tous les tests doivent passer
```

Les fichiers `*.freezed.dart` et `*.g.dart` sont générés — ne jamais les modifier manuellement.

## Structure

```
lib/
├── core/          # Result<T,E>, AppError, SecureKey
├── data/          # Modèles Freezed, stockage JSON, SSH
├── domain/        # SshService, SnippetService, AnsiService
└── presentation/  # Providers Riverpod, écrans, widgets
```

Documentation technique complète : [docs/TECHNICAL.md](docs/TECHNICAL.md)
