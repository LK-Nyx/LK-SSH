# Phase 1 — Auth & Host Trust (design)

**Date** : 2026-04-27
**Statut** : design validé, plan d'implémentation à écrire ensuite
**Portée** : refonte de la couche d'authentification SSH et ajout de la vérification d'empreinte d'hôte (TOFU). Préparation du multi-keys.

---

## Contexte

LK-SSH v1 ne supporte qu'une seule méthode d'authentification (clé SSH) et **ne vérifie pas l'empreinte d'hôte** (`SSHClient` instancié sans `onVerifyHostKey` dans `lib/domain/services/ssh_service.dart`). Conséquences :

- Impossible de se connecter à un serveur configuré pour `password` ou `keyboard-interactive` (très courant : 2FA, serveurs partagés, machines fraîches sans clé déposée).
- Une seule clé SSH stockée pour toute l'app : pas de séparation perso/pro.
- Trou MitM : un attaquant en position peut se faire passer pour le serveur sans détection.

Cette phase couvre les trois axes ensemble parce qu'ils touchent le même code path (`Server` model, `SshClientFactory.connect()`, `server_form_screen`). Les faire séparément = repasser 3× au même endroit.

---

## Objectifs

1. Supporter trois méthodes d'auth choisies explicitement par serveur : `key`, `password`, `keyboardInteractive`.
2. Vérifier l'empreinte d'hôte selon une stratégie TOFU avec auto-pin silencieux à la 1ère connexion et alerte explicite en cas de mismatch.
3. Permettre l'enregistrement de plusieurs clés SSH avec assignation par serveur.
4. Ne pas régresser sur le flux v1 (un user qui utilisait sa clé doit pouvoir continuer sans intervention manuelle).

Hors-scope (réservés à des phases ultérieures) :

- Génération de clé SSH dans l'app
- Agent forwarding, jump hosts
- Édition manuelle des fingerprints stockés (faisable au besoin via reset known_hosts)
- Auth par certificat SSH

---

## Décisions de design

### D1 — Méthode d'authentification : explicite par serveur

`Server.authMethod` est un enum `AuthMethod { key, password, keyboardInteractive }`, choisi au formulaire serveur. Pas de fallback automatique : si `key` est sélectionné et que l'auth échoue, la connexion échoue (pas d'essai password derrière).

**Justification** : explicite > magique pour un outil dev. Évite les essais inutiles qui déclenchent fail2ban ou similaires côté serveur. Simplifie le `Server` model et le code de connexion.

### D2 — Password : opt-in "se souvenir"

Si `authMethod == password`, le formulaire affiche un champ password masqué + une checkbox "Se souvenir". Si cochée, le password est stocké via le mode courant (A : `FlutterSecureStorage` ; D : AES-GCM + Argon2id). Si non cochée, le password n'est jamais persisté et est redemandé à chaque connexion.

### D3 — known_hosts : TOFU auto-pin + alerte sur mismatch

- **1ère connexion** (host:port inconnu) : auto-pin silencieux du fingerprint SHA256 de la host key. Comportement équivalent à `ssh -o StrictHostKeyChecking=accept-new`.
- **Mismatch** (host:port connu, fingerprint différent) : bottom sheet rouge bloquante avec ancien fingerprint, nouveau fingerprint, et trois actions : `Annuler`, `Voir les détails`, `Faire confiance à la nouvelle empreinte`. La connexion ne procède que si l'utilisateur accepte explicitement.
- **Storage** : `Map<String hostPortKey, String sha256Base64>` sérialisé en JSON, non chiffré (le fingerprint est public).

**Justification du auto-pin silencieux** : afficher une bottom sheet à chaque nouveau serveur va faire que les users tap "trust" sans lire, ce qui annule l'intérêt sécuritaire. L'attaque MitM à la 1ère connexion suppose un attaquant déjà en position au moment exact où l'on tape Enter — rare en pratique. La vraie valeur sécuritaire est sur le mismatch.

### D4 — Multi-keys : registry central + référence par id

Nouveau modèle `SshKey { id, label, addedAt }`. Les bytes de clé (et la passphrase associée si la clé est chiffrée) sont stockés via `ISecureKeyStorage` existant, indexés par l'id. `Server.keyId : String?` pointe vers la clé à utiliser ; nullable parce que `authMethod != key` n'a pas besoin de clé.

### D5 — UX d'assignation de clé : dropdown + ajout inline

Au formulaire serveur, si `authMethod == key`, un dropdown liste les clés enregistrées + un bouton "+ Nouvelle clé" qui ouvre une bottom sheet d'éditeur de clé (label, paste PEM, passphrase optionnelle). Évite la friction "fermer le form, aller dans settings, ajouter, revenir".

### D6 — Écran de gestion des clés dédié

Nouvel écran `keys_screen` accessible depuis `settings`. Liste les `SshKey` avec label, date d'ajout, nombre de serveurs qui l'utilisent. Actions : éditer label, supprimer (avec confirmation explicite si la clé est utilisée par N serveurs ; suppression en cascade fait basculer ces serveurs vers un état "clé manquante" qu'ils doivent corriger).

**Justification (vs section inline dans settings)** : prépare le terrain pour génération in-app et import/export futurs sans réécrire l'UI.

### D7 — Passphrase sur clé importée : supportée

Beaucoup de clés OpenSSH générées par `ssh-keygen` ont une passphrase. `SSHKeyPair.fromPem` accepte un paramètre `passphrase`. La bottom sheet d'édition de clé propose un champ passphrase optionnel. La passphrase est stockée à côté des bytes de clé via le même `ISecureKeyStorage`.

---

## Modèles de données

### `AuthMethod` (enum)

```dart
enum AuthMethod { key, password, keyboardInteractive }
```

### `Server` (modifié)

```dart
@freezed
class Server with _$Server {
  const factory Server({
    required String id,
    required String label,
    required String host,
    required int port,
    required String username,
    @Default(AuthMethod.key) AuthMethod authMethod,
    String? keyId,                 // requis si authMethod == key, ignoré sinon
    @Default(false) bool savePassword,
  }) = _Server;
}
```

### `SshKey` (nouveau)

```dart
@freezed
class SshKey with _$SshKey {
  const factory SshKey({
    required String id,            // UUID v4
    required String label,         // ex: "MacBook perso"
    required DateTime addedAt,
  }) = _SshKey;
}
```

Les bytes et la passphrase ne sont pas dans le modèle Freezed — ils restent dans `ISecureKeyStorage` indexés par `id`.

### Persistence additions

| Storage | Format | Chiffrement |
|---|---|---|
| `SshKey` (métadonnées) | `keys.json` (liste) | non |
| Bytes de clé + passphrase | via `ISecureKeyStorage` | mode courant (A ou D) |
| Password serveur | via `ISecureKeyStorage` ou clone, indexé par `serverId` | mode courant |
| `known_hosts` | `known_hosts.json` (`Map<String, String>`) | non (fingerprint public) |

---

## Architecture

### Couche auth

```dart
abstract interface class SshClientFactory {
  Future<Result<SSHClient, AppError>> connect({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  });
}

sealed class AuthCredentials {
  const AuthCredentials();
}

final class KeyCreds extends AuthCredentials {
  const KeyCreds({required this.bytes, this.passphrase});
  final Uint8List bytes;
  final String? passphrase;
}

final class PasswordCreds extends AuthCredentials {
  const PasswordCreds(this.password);
  final String password;
}

final class InteractiveCreds extends AuthCredentials {
  const InteractiveCreds(this.onPrompt);
  final Future<List<String>> Function(SSHUserInfoRequest) onPrompt;
}
```

### `HostKeyVerifier`

```dart
class HostKeyVerifier {
  HostKeyVerifier({
    required IKnownHostsStorage storage,
    required Future<HostKeyDecision> Function(HostKeyChange change) onMismatch,
  });

  // Handler async passé à SSHClient via onVerifyHostKey (dartssh2 supporte Future<bool>).
  // Logique :
  // - inconnu → auto-pin, return true
  // - connu et identique → return true
  // - connu et différent → invoque onMismatch, applique la décision
  //   (acceptAndPin → save + true ; acceptOnce → true sans save ; reject → false)
  Future<bool> verify({
    required String host,
    required int port,
    required String fingerprintSha256,
  });
}

enum HostKeyDecision { reject, acceptOnce, acceptAndPin }

class HostKeyChange {
  final String host;
  final int port;
  final String oldFingerprint;
  final String newFingerprint;
}
```

`onMismatch` est injecté par la couche présentation — c'est elle qui affiche la bottom sheet et résout le `Future<HostKeyDecision>`.

### Providers Riverpod

| Provider | Rôle |
|---|---|
| `sshKeysNotifierProvider` | CRUD sur les `SshKey` (métadonnées + bytes) |
| `passwordStorageProvider` | lookup/save/delete par `serverId` |
| `knownHostsStorageProvider` | lookup/save/delete par `host:port` |
| `hostKeyVerifierProvider` | compose les 2 précédents + une factory de UI callback |
| `sshNotifierProvider(sessionId)` | modifié : lit `authMethod`, charge les credentials, expose un `Stream<AuthPromptRequest>` consommé par `terminal_screen` |

### Flow de connexion

```
terminal_screen ouvre une session
  → sshNotifier(sessionId).connect()
    → lit Server.authMethod
    → branche A (key) : charge bytes via SshKeyRegistry.load(server.keyId)
                        → KeyCreds(bytes, passphrase)
    → branche B (password) : si savePassword → load → PasswordCreds
                              sinon → emit AuthPromptRequest.password
                                    → wait Completer<String>
                                    → PasswordCreds
    → branche C (interactive) : InteractiveCreds(onPrompt) où onPrompt
                                → emit AuthPromptRequest.kbInteractive(prompts)
                                → wait Completer<List<String>>
    → SshClientFactory.connect(server, credentials, verifier)
      → verifier.verify déclenché par dartssh2 sur la host key
        → si mismatch : verifier.onMismatch
                        → emit AuthPromptRequest.hostKeyMismatch
                        → wait Completer<HostKeyDecision>
```

---

## Flows UX

### F-1 — Formulaire serveur

Une nouvelle section "Authentification" :

- Dropdown `AuthMethod` (3 valeurs)
- Si `key` : sous-dropdown des `SshKey` enregistrées + bouton "+ Nouvelle clé" qui ouvre `KeyEditorSheet`
- Si `password` : champ password masqué + checkbox "Se souvenir" (visible seulement si le champ est non vide)
- Si `keyboardInteractive` : aucun champ — annonce "Les questions du serveur s'afficheront à la connexion"

**Validation form** : si `authMethod == key`, le bouton Sauvegarder est désactivé tant que `keyId` est null (aucune clé sélectionnée). Si la liste de clés est vide, le sous-dropdown affiche "Aucune clé enregistrée — ajoutez-en une via le bouton +".

`KeyEditorSheet` (réutilisable) : champ label, champ PEM (multi-ligne, paste-friendly), champ passphrase optionnel. Bouton "Tester" qui essaie `SSHKeyPair.fromPem(pem, passphrase: ...)` et affiche une erreur claire si la passphrase est mauvaise ou la clé invalide. Sauvegarde uniquement si parse OK.

### F-2 — Écran de gestion clés (`keys_screen`)

Accessible depuis settings, sous une section "Clés SSH" :

- Liste : pour chaque `SshKey` → label + date + "utilisée par N serveurs"
- Actions par item : éditer label, supprimer (confirmation explicite si N>0)
- Bouton flottant "Ajouter une clé" → ouvre `KeyEditorSheet`

Si suppression d'une clé utilisée → les serveurs concernés gardent leur `keyId` orphelin. Au prochain connect, le `sshNotifier` détecte que `SshKeyRegistry.load(keyId)` retourne null et émet un `AppError.missingKey` ; le `terminal_screen` affiche un message clair "Clé `<id>` introuvable. Ouvrir le serveur pour réassigner une clé." avec un bouton qui pousse `server_form_screen`. Pas de connexion silencieuse en mode dégradé.

### F-3 — Bottom sheets de prompt à la connexion

Affichées par `terminal_screen` quand le `sshNotifier` émet un `AuthPromptRequest`.

- **`PasswordPromptSheet`** : titre `Mot de passe pour user@host`, champ masqué, bouton Annuler / Connecter. Pas de checkbox "se souvenir" ici (c'est une saisie ponctuelle).
- **`KeyboardInteractiveSheet`** : titre = nom du challenge serveur, pour chaque `SSHUserInfoPrompt` un champ texte (masqué si `prompt.echo == false`), bouton Annuler / Soumettre.
- **`HostKeyMismatchSheet`** : style alerte rouge, message court "L'empreinte du serveur a changé depuis la dernière connexion. Cela peut indiquer un changement légitime du serveur ou une attaque MitM."
  - Bloc fingerprint ancien / nouveau côte à côte
  - Boutons : `Annuler` (default, gros), `Voir les détails` (toggle un panneau avec les fingerprints en clair + algo), `Faire confiance à la nouvelle empreinte` (rouge, secondaire)

---

## Migration

Au démarrage, après l'init des storages, vérifier le flag `migration_p1_done` dans settings. S'il est absent et que `secureKeyStorage.hasKey()` :

1. Lire les bytes de la clé existante
2. Créer un `SshKey(id="default", label="Clé par défaut", addedAt=now)`
3. Stocker les bytes via `SshKeyRegistry.save("default", bytes, passphrase: null)`
4. Pour chaque `Server` existant : `authMethod = key, keyId = "default"`
5. Sauvegarder `servers.json.pre-p1` avant l'écriture finale (filet de sécurité)
6. Set `migration_p1_done = true`

Migration idempotente : ré-exécuter la migration ne fait rien (le flag est lu en premier).

---

## Tests

### Tests unitaires (obligatoires P1)

| Sujet | Couverture |
|---|---|
| Modèles | sérialisation/désérialisation `Server`/`SshKey`, valeurs par défaut |
| Migration | passe v1 → P1 idempotente, restore depuis backup en cas de fail |
| `IKnownHostsStorage` | round-trip JSON, get manquant, suppression |
| `IPasswordStorage` | round-trip avec mode A et mode D, suppression cascade au delete server |
| `ISshKeyRegistry` | CRUD complet, suppression cascade des bytes |
| `HostKeyVerifier` | 3 branches (inconnu, identique, mismatch), décisions `reject`/`acceptOnce`/`acceptAndPin` |
| `SshClientFactory.connect` | 3 méthodes d'auth dispatchent vers le bon code, erreurs propagées en `Result.err` |

### Tests widget (non-bloquants P1)

Smoke-test manuel jugé suffisant. Tests widget seront ajoutés en suivi si régressions observées.

### Tests manuels sur device (gating release)

- Serveur réel #1 : auth `key` (cas v1, vérifie que la migration n'a rien cassé)
- Serveur réel #2 : auth `password` avec et sans "Se souvenir"
- Serveur réel #3 : auth `keyboardInteractive` (idéalement un serveur 2FA)
- Modifier manuellement le fingerprint stocké pour le serveur #1, relancer → bottom sheet mismatch doit apparaître, choix "annuler" doit empêcher la connexion, choix "accepter" doit mettre à jour le fingerprint
- Test passphrase : importer une clé chiffrée avec mauvaise passphrase → erreur claire ; bonne passphrase → connect OK

---

## Plan d'implémentation (steps)

Chaque step : `flutter analyze --fatal-infos` clean + `dart run build_runner build --delete-conflicting-outputs` ré-exécuté quand nécessaire.

1. **Modèles & migration** — étendre `Server`, créer `SshKey`, écrire la migration + tests
2. **Storage layers** — `JsonStorageService` étendu, `IKnownHostsStorage`, `IPasswordStorage`, `ISshKeyRegistry` + tests
3. **Couche auth + `HostKeyVerifier`** — refonte `SshClientFactory.connect`, sealed `AuthCredentials`, verifier complet + tests
4. **Providers Riverpod** — les 4 nouveaux providers, refonte `sshNotifier` avec stream de prompts + tests avec storages mock
5. **UI : écran clés + form serveur** — `keys_screen`, `KeyEditorSheet`, refonte section auth dans `server_form_screen`
6. **UI : prompts à la connexion** — 3 bottom sheets, listener stream dans `terminal_screen`, smoke test manuel sur device

---

## Risques

| Risque | Probabilité | Mitigation |
|---|---|---|
| Migration corrompt les serveurs existants | moyenne | flag idempotent + sauvegarde `servers.json.pre-p1` ; migration testée unitairement |
| Lifecycle prompt : user quitte l'écran pendant un prompt → fuite Completer | élevée si non géré | tous les prompts via `Completer` géré par le notifier, cancel dans `dispose()` |
| Passphrase mauvaise à l'import → exception non gérée | moyenne | try/catch à `SSHKeyPair.fromPem`, message clair, ne pas persister si parse fail |
| Suppression d'une clé partagée par N serveurs sans confirmation → connexions cassées | moyenne | confirmation dialog explicite avec liste des serveurs impactés ; serveurs orphelins affichent un état "clé manquante" lisible |
| Mismatch fingerprint affiché trop tard (après que dartssh2 a déjà commencé l'auth) | faible | utiliser `onVerifyHostKey` qui est appelé avant l'auth ; vérifier le timing avec un test d'intégration |

---

## Fichiers touchés (estimation)

Nouveaux :

- `lib/data/models/ssh_key.dart`
- `lib/data/models/auth_method.dart` (ou intégré à `server.dart`)
- `lib/data/storage/i_known_hosts_storage.dart` + impl
- `lib/data/storage/i_password_storage.dart` + impl
- `lib/data/storage/i_ssh_key_registry.dart` + impl
- `lib/domain/services/host_key_verifier.dart`
- `lib/presentation/providers/ssh_keys_provider.dart`
- `lib/presentation/providers/password_storage_provider.dart`
- `lib/presentation/providers/known_hosts_provider.dart`
- `lib/presentation/providers/host_key_verifier_provider.dart`
- `lib/presentation/screens/keys_screen.dart`
- `lib/presentation/widgets/key_editor_sheet.dart`
- `lib/presentation/widgets/password_prompt_sheet.dart`
- `lib/presentation/widgets/keyboard_interactive_sheet.dart`
- `lib/presentation/widgets/host_key_mismatch_sheet.dart`
- Tests unitaires correspondants sous `test/`

Modifiés :

- `lib/data/models/server.dart` (3 champs ajoutés)
- `lib/data/storage/i_storage_service.dart` + `json_storage_service.dart` (extensions CRUD)
- `lib/domain/services/ssh_service.dart` (refonte signature `connect`)
- `lib/presentation/providers/ssh_provider.dart` (lit authMethod, expose stream prompts)
- `lib/presentation/screens/server_form_screen.dart` (section auth)
- `lib/presentation/screens/settings_screen.dart` (entrée "Clés SSH")
- `lib/presentation/screens/terminal_screen.dart` (listener stream prompts)
- `docs/TECHNICAL.md` (doc post-impl)
