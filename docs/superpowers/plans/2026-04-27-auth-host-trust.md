# Auth & Host Trust Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add password / keyboard-interactive auth, multi-keys with per-server assignment, and TOFU host-key verification — without breaking the v1 single-key flow.

**Architecture:** New `SshKey` registry indexes multiple SSH keys, `Server` gains `authMethod`/`keyId`/`savePassword`, `SshClientFactory.connect` is refactored around a sealed `AuthCredentials` and a `HostKeyVerifier`. Connection prompts (password / KI / mismatch) flow through a `Stream<AuthPromptRequest>` exposed by `sshNotifier` and consumed by `terminal_screen`.

**Tech Stack:** Flutter 3.19+ · Dart 3.3+ · Riverpod 2 · Freezed · dartssh2 · flutter_secure_storage · cryptography · `flutter_test` + `mocktail`.

**Spec:** [docs/superpowers/specs/2026-04-27-auth-host-trust-design.md](../specs/2026-04-27-auth-host-trust-design.md)

---

## Mode D handling — boot-time unlock

Mode D (`KeyStorageMode.passphraseProtected`) requires the user passphrase to derive the AES-GCM key with Argon2id. Today it's asked ad-hoc on every `loadKey` call. Multi-keys in mode D requires a **vault** chiffré (`SshKeyRegistryD`) holding `Map<keyId, {bytes, passphrase}>`, decrypted once at app boot and held in memory for the session.

The plan introduces a new **boot unlock flow** (Step 4) that runs before any provider that needs a key:

1. App starts → load `Settings`. If `keyStorageMode == passphraseProtected` AND there is a vault file or a legacy mode-D key on disk → push `UnlockScreen`.
2. User types passphrase. The app verifies by attempting to decrypt the vault (or, on first run post-P1 with no vault yet, the legacy mode-D key).
3. On success, the passphrase goes into `vaultPassphraseProvider` (in-memory only, never persisted) and the screen is replaced by the home screen. The migration runs after unlock and can move the legacy bytes into the vault.
4. On wrong passphrase → re-prompt.
5. The passphrase can be cleared from memory by a "Lock" action in settings (sets `vaultPassphraseProvider` back to null and pushes `UnlockScreen` again).

For mode A (default), no unlock is needed and the app boots straight into the home screen.

---

## Pre-flight: verify dartssh2 callback signatures

dartssh2 v2.9.x is in `pubspec.yaml`. Some callback names/signatures matter for Tasks 3.x. Verify locally before locking implementation:

```bash
grep -E "onPasswordRequest|onUserInfoRequest|onVerifyHostKey|SSHKeyPair.fromPem" \
  $(find ~/.pub-cache -path "*dartssh2*" -name "*.dart") | head -30
```

Expected signatures (matching dartssh2 README and current usage):

- `SSHKeyPair.fromPem(String pem, [String? passphrase]) → List<SSHKeyPair>` (it returns a list — the existing v1 code uses it as `identities: SSHKeyPair.fromPem(...)` and that compiles, confirming `identities` accepts a `List<SSHKeyPair>`)
- `onPasswordRequest: FutureOr<String?> Function()`
- `onUserInfoRequest: FutureOr<List<String>?> Function(SSHUserInfoRequest)` where `SSHUserInfoRequest` exposes `name`, `instruction`, `prompts: List<SSHUserInfoPrompt>`, and `SSHUserInfoPrompt` exposes `prompt` and `echo`
- `onVerifyHostKey: FutureOr<bool> Function(String type, Uint8List key)`

If grep shows any divergence, **adjust the corresponding Task before implementing**. This is a 30-second sanity check that prevents whole branches of work from compiling.

---

## File Structure

### New files

| Path | Responsibility |
|---|---|
| `lib/data/models/auth_method.dart` | enum `AuthMethod` |
| `lib/data/models/ssh_key.dart` | Freezed `SshKey { id, label, addedAt }` |
| `lib/data/models/auth_credentials.dart` | sealed `AuthCredentials` (Key/Password/Interactive) |
| `lib/data/models/auth_prompt_request.dart` | sealed `AuthPromptRequest` (Password/KbInteractive/HostKeyMismatch) + `HostKeyDecision` enum + `HostKeyChange` |
| `lib/data/storage/i_known_hosts_storage.dart` | interface for fingerprint persistence |
| `lib/data/storage/json_known_hosts_storage.dart` | JSON-on-disk implementation |
| `lib/data/storage/i_password_storage.dart` | interface for per-server password persistence |
| `lib/data/storage/secure_password_storage.dart` | implementation using FlutterSecureStorage (or vault, depending on mode) |
| `lib/data/ssh/i_ssh_key_registry.dart` | interface for multi-key storage |
| `lib/data/ssh/ssh_key_registry_a.dart` | mode A impl (FlutterSecureStorage indexed by id) |
| `lib/data/ssh/ssh_key_registry_d.dart` | mode D impl (Argon2id+AES-GCM vault) |
| `lib/domain/services/host_key_verifier.dart` | TOFU + mismatch handler |
| `lib/presentation/providers/ssh_keys_provider.dart` | `sshKeyRegistryProvider` (mode-aware async) + `sshKeysNotifierProvider` |
| `lib/presentation/providers/password_storage_provider.dart` | `passwordStorageProvider` |
| `lib/presentation/providers/known_hosts_provider.dart` | `knownHostsStorageProvider` |
| `lib/presentation/providers/host_key_verifier_provider.dart` | `hostKeyVerifierProvider` |
| `lib/presentation/providers/vault_passphrase_provider.dart` | in-memory unlock state for mode D |
| `lib/presentation/screens/unlock_screen.dart` | mode D boot-time passphrase entry |
| `lib/presentation/screens/keys_screen.dart` | manage saved keys |
| `lib/presentation/widgets/key_editor_sheet.dart` | reusable bottom sheet to add/edit a key |
| `lib/presentation/widgets/password_prompt_sheet.dart` | password prompt during connect |
| `lib/presentation/widgets/keyboard_interactive_sheet.dart` | KI challenge prompt |
| `lib/presentation/widgets/host_key_mismatch_sheet.dart` | mismatch alert |
| `lib/data/migration/p1_auth_migration.dart` | one-shot migration runner |
| Tests: `test/data/models/server_authmethod_test.dart`, `test/data/models/ssh_key_test.dart`, `test/data/storage/json_known_hosts_storage_test.dart`, `test/data/storage/secure_password_storage_test.dart`, `test/data/ssh/ssh_key_registry_a_test.dart`, `test/data/ssh/ssh_key_registry_d_test.dart`, `test/domain/services/host_key_verifier_test.dart`, `test/data/migration/p1_auth_migration_test.dart`, `test/domain/services/ssh_service_authmethod_test.dart` |

### Modified files

| Path | Change |
|---|---|
| `lib/data/models/server.dart` | add `authMethod`, `keyId?`, `savePassword` |
| `lib/data/models/auth_method.dart` (new, but it's the new enum) | — |
| `lib/data/storage/i_storage_service.dart` | add `loadSshKeys` / `saveSshKeys` |
| `lib/data/storage/json_storage_service.dart` | implement the two new methods (reuse `_loadList`/`_saveList`) |
| `lib/domain/services/ssh_service.dart` | refactor `SshClientFactory.connect`, `SSHService.connect` |
| `lib/presentation/providers/ssh_provider.dart` | dispatch by `authMethod`, expose `Stream<AuthPromptRequest>` |
| `lib/presentation/providers/servers_provider.dart` | adapt `newServer(...)` defaults |
| `lib/presentation/screens/server_form_screen.dart` | add auth section (dropdown + key picker + password field) |
| `lib/presentation/screens/settings_screen.dart` | entry to `keys_screen` |
| `lib/presentation/screens/terminal_screen.dart` | listen to prompt stream |
| `docs/TECHNICAL.md` | document P1 (post-implementation) |

### Conventions

- Run `dart run build_runner build --delete-conflicting-outputs` after every change to a `@freezed` or `@riverpod` source. The plan calls this out explicitly each time.
- Run `flutter analyze --fatal-infos` after each task before committing.
- Run `flutter test <path>` for the file you just wrote a test for.
- Each task ends with `git add` + `git commit -m "<conventional message>"`.

---

## Step 1 — Models & migration

### Task 1.1: Create `AuthMethod` enum

**Files:**
- Create: `lib/data/models/auth_method.dart`

- [ ] **Step 1: Write the file**

```dart
enum AuthMethod {
  key,
  password,
  keyboardInteractive,
}
```

- [ ] **Step 2: Run analyze**

Run: `flutter analyze --fatal-infos lib/data/models/auth_method.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/data/models/auth_method.dart
git commit -m "feat: AuthMethod enum (key/password/keyboardInteractive)"
```

---

### Task 1.2: Extend `Server` with auth fields (test first)

**Files:**
- Test: `test/data/models/server_authmethod_test.dart`
- Modify: `lib/data/models/server.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/server_authmethod_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/auth_method.dart';
import 'package:lk_ssh/data/models/server.dart';

void main() {
  group('Server with auth fields', () {
    test('default authMethod is key, keyId null, savePassword false', () {
      const s = Server(id: 'x', label: 'x', host: 'h', username: 'u');
      expect(s.authMethod, AuthMethod.key);
      expect(s.keyId, null);
      expect(s.savePassword, false);
    });

    test('json round-trip preserves new fields', () {
      const original = Server(
        id: 'x',
        label: 'x',
        host: 'h',
        username: 'u',
        authMethod: AuthMethod.password,
        keyId: 'k1',
        savePassword: true,
      );
      final restored = Server.fromJson(original.toJson());
      expect(restored, original);
    });

    test('json round-trip on a v1-style payload uses defaults', () {
      final v1Json = {
        'id': 'x', 'label': 'x', 'host': 'h', 'port': 22, 'username': 'u',
      };
      final restored = Server.fromJson(v1Json);
      expect(restored.authMethod, AuthMethod.key);
      expect(restored.keyId, null);
      expect(restored.savePassword, false);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/server_authmethod_test.dart`
Expected: FAIL — `authMethod` getter doesn't exist on `Server`.

- [ ] **Step 3: Update `Server` model**

```dart
// lib/data/models/server.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth_method.dart';

part 'server.freezed.dart';
part 'server.g.dart';

@freezed
class Server with _$Server {
  const factory Server({
    required String id,
    required String label,
    required String host,
    @Default(22) int port,
    required String username,
    @Default(AuthMethod.key) AuthMethod authMethod,
    String? keyId,
    @Default(false) bool savePassword,
  }) = _Server;

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
}
```

- [ ] **Step 4: Regenerate freezed/json**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded after Xs`. New `server.freezed.dart` includes the new fields.

- [ ] **Step 5: Run tests + analyze**

Run: `flutter test test/data/models/server_authmethod_test.dart && flutter analyze --fatal-infos`
Expected: tests PASS + `No issues found!`. The existing tests calling `Server(...)` should still pass because all new fields have defaults.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/server.dart lib/data/models/server.freezed.dart lib/data/models/server.g.dart test/data/models/server_authmethod_test.dart
git commit -m "feat: extend Server with authMethod/keyId/savePassword"
```

---

### Task 1.3: Create `SshKey` model (test first)

**Files:**
- Test: `test/data/models/ssh_key_test.dart`
- Create: `lib/data/models/ssh_key.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/models/ssh_key_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/ssh_key.dart';

void main() {
  test('SshKey json round-trip', () {
    final original = SshKey(
      id: 'abc',
      label: 'MacBook perso',
      addedAt: DateTime.utc(2026, 4, 27, 10, 30),
    );
    final restored = SshKey.fromJson(original.toJson());
    expect(restored, original);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/ssh_key_test.dart`
Expected: FAIL — `SshKey` doesn't exist.

- [ ] **Step 3: Write the model**

```dart
// lib/data/models/ssh_key.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_key.freezed.dart';
part 'ssh_key.g.dart';

@freezed
class SshKey with _$SshKey {
  const factory SshKey({
    required String id,
    required String label,
    required DateTime addedAt,
  }) = _SshKey;

  factory SshKey.fromJson(Map<String, dynamic> json) => _$SshKeyFromJson(json);
}
```

- [ ] **Step 4: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test + analyze**

Run: `flutter test test/data/models/ssh_key_test.dart && flutter analyze --fatal-infos`
Expected: PASS + clean.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/ssh_key.dart lib/data/models/ssh_key.freezed.dart lib/data/models/ssh_key.g.dart test/data/models/ssh_key_test.dart
git commit -m "feat: add SshKey model (id/label/addedAt)"
```

---

### Task 1.4: Add `migrationP1Done` flag to `Settings`

**Files:**
- Modify: `lib/data/models/settings.dart`

- [ ] **Step 1: Add the field**

In `lib/data/models/settings.dart`, after `fileDebugMode`:

```dart
@Default(false) bool migrationP1Done,
```

- [ ] **Step 2: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Verify existing settings tests still pass**

Run: `flutter test test/ && flutter analyze --fatal-infos`
Expected: all tests PASS, analyze clean.

- [ ] **Step 4: Commit**

```bash
git add lib/data/models/settings.dart lib/data/models/settings.freezed.dart lib/data/models/settings.g.dart
git commit -m "feat: add migrationP1Done flag to Settings"
```

---

## Step 2 — Storage layers

### Task 2.1: `IKnownHostsStorage` + `JsonKnownHostsStorage` (test first)

**Files:**
- Test: `test/data/storage/json_known_hosts_storage_test.dart`
- Create: `lib/data/storage/i_known_hosts_storage.dart`
- Create: `lib/data/storage/json_known_hosts_storage.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/storage/json_known_hosts_storage_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/storage/json_known_hosts_storage.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lk_ssh_kh_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('save then load returns the fingerprint', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('example.com', 22, 'SHA256:abc');
    expect(await storage.load('example.com', 22), 'SHA256:abc');
  });

  test('load returns null when host:port is unknown', () async {
    final storage = JsonKnownHostsStorage(tmp);
    expect(await storage.load('unknown.com', 22), null);
  });

  test('save overwrites a previous fingerprint', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('h.com', 22, 'SHA256:old');
    await storage.save('h.com', 22, 'SHA256:new');
    expect(await storage.load('h.com', 22), 'SHA256:new');
  });

  test('delete removes the entry', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('h.com', 22, 'SHA256:abc');
    await storage.delete('h.com', 22);
    expect(await storage.load('h.com', 22), null);
  });

  test('host:port distinguishes entries', () async {
    final storage = JsonKnownHostsStorage(tmp);
    await storage.save('h.com', 22, 'A');
    await storage.save('h.com', 2222, 'B');
    expect(await storage.load('h.com', 22), 'A');
    expect(await storage.load('h.com', 2222), 'B');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/storage/json_known_hosts_storage_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Write the interface**

```dart
// lib/data/storage/i_known_hosts_storage.dart
abstract interface class IKnownHostsStorage {
  Future<String?> load(String host, int port);
  Future<void> save(String host, int port, String fingerprint);
  Future<void> delete(String host, int port);
}
```

- [ ] **Step 4: Write the implementation**

```dart
// lib/data/storage/json_known_hosts_storage.dart
import 'dart:convert';
import 'dart:io';

import 'i_known_hosts_storage.dart';

final class JsonKnownHostsStorage implements IKnownHostsStorage {
  JsonKnownHostsStorage(this._directory);

  final Directory _directory;

  File get _file => File('${_directory.path}/known_hosts.json');

  String _key(String host, int port) => '$host:$port';

  Future<Map<String, String>> _read() async {
    if (!await _file.exists()) return {};
    try {
      final raw = await _file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, String> data) async {
    await _file.writeAsString(jsonEncode(data));
  }

  @override
  Future<String?> load(String host, int port) async =>
      (await _read())[_key(host, port)];

  @override
  Future<void> save(String host, int port, String fingerprint) async {
    final data = await _read();
    data[_key(host, port)] = fingerprint;
    await _write(data);
  }

  @override
  Future<void> delete(String host, int port) async {
    final data = await _read();
    data.remove(_key(host, port));
    await _write(data);
  }
}
```

- [ ] **Step 5: Run test + analyze**

Run: `flutter test test/data/storage/json_known_hosts_storage_test.dart && flutter analyze --fatal-infos`
Expected: 5/5 tests PASS, analyze clean.

- [ ] **Step 6: Commit**

```bash
git add lib/data/storage/i_known_hosts_storage.dart lib/data/storage/json_known_hosts_storage.dart test/data/storage/json_known_hosts_storage_test.dart
git commit -m "feat: JsonKnownHostsStorage for TOFU fingerprint persistence"
```

---

### Task 2.2: `IPasswordStorage` + `SecurePasswordStorage` (test first)

**Files:**
- Test: `test/data/storage/secure_password_storage_test.dart`
- Create: `lib/data/storage/i_password_storage.dart`
- Create: `lib/data/storage/secure_password_storage.dart`

This implementation uses `FlutterSecureStorage` directly (independent of mode A/D). The only "secret" stored is the password — chiffrement OS-level via Android Keystore is sufficient. Mode D users still get an extra layer because the *key material* (the most sensitive item) goes through Argon2id; passwords are a softer secret.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/storage/secure_password_storage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/storage/secure_password_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _MockSecure extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecure secure;
  late SecurePasswordStorage storage;

  setUp(() {
    secure = _MockSecure();
    storage = SecurePasswordStorage.forTest(secure);
  });

  test('save writes under namespaced key', () async {
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    await storage.save('srv1', 'p4ss');
    verify(() => secure.write(key: 'pwd_srv1', value: 'p4ss')).called(1);
  });

  test('load returns the stored value', () async {
    when(() => secure.read(key: 'pwd_srv1')).thenAnswer((_) async => 'p4ss');
    expect(await storage.load('srv1'), 'p4ss');
  });

  test('load returns null when missing', () async {
    when(() => secure.read(key: 'pwd_missing')).thenAnswer((_) async => null);
    expect(await storage.load('missing'), null);
  });

  test('delete removes the stored value', () async {
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await storage.delete('srv1');
    verify(() => secure.delete(key: 'pwd_srv1')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/storage/secure_password_storage_test.dart`
Expected: FAIL — class does not exist.

- [ ] **Step 3: Write the interface**

```dart
// lib/data/storage/i_password_storage.dart
abstract interface class IPasswordStorage {
  Future<String?> load(String serverId);
  Future<void> save(String serverId, String password);
  Future<void> delete(String serverId);
}
```

- [ ] **Step 4: Write the implementation**

```dart
// lib/data/storage/secure_password_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'i_password_storage.dart';

final class SecurePasswordStorage implements IPasswordStorage {
  SecurePasswordStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  SecurePasswordStorage.forTest(this._storage);

  final FlutterSecureStorage _storage;

  String _key(String serverId) => 'pwd_$serverId';

  @override
  Future<String?> load(String serverId) =>
      _storage.read(key: _key(serverId));

  @override
  Future<void> save(String serverId, String password) =>
      _storage.write(key: _key(serverId), value: password);

  @override
  Future<void> delete(String serverId) =>
      _storage.delete(key: _key(serverId));
}
```

- [ ] **Step 5: Run test + analyze**

Run: `flutter test test/data/storage/secure_password_storage_test.dart && flutter analyze --fatal-infos`
Expected: PASS + clean.

- [ ] **Step 6: Commit**

```bash
git add lib/data/storage/i_password_storage.dart lib/data/storage/secure_password_storage.dart test/data/storage/secure_password_storage_test.dart
git commit -m "feat: SecurePasswordStorage (FlutterSecureStorage-backed)"
```

---

### Task 2.3: `ISshKeyRegistry` interface

**Files:**
- Create: `lib/data/ssh/i_ssh_key_registry.dart`

- [ ] **Step 1: Write the interface**

```dart
// lib/data/ssh/i_ssh_key_registry.dart
import 'dart:typed_data';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';

abstract interface class ISshKeyRegistry {
  /// Stores key bytes (and optional passphrase) under [keyId].
  /// Caller is responsible for generating [keyId] (UUID).
  Future<Result<void, AppError>> save({
    required String keyId,
    required Uint8List bytes,
    String? passphrase,
  });

  /// Loads the key bytes for [keyId]. Returns `KeyNotFoundError` if absent.
  Future<Result<SecureKey, AppError>> loadBytes(String keyId);

  /// Loads the optional passphrase for [keyId]. Returns null if no passphrase
  /// was stored (key was unencrypted at import time).
  Future<String?> loadPassphrase(String keyId);

  Future<Result<void, AppError>> delete(String keyId);
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/data/ssh/i_ssh_key_registry.dart
git commit -m "feat: ISshKeyRegistry interface"
```

---

### Task 2.4: `SshKeyRegistryA` (mode A — FlutterSecureStorage indexed) — test first

**Files:**
- Test: `test/data/ssh/ssh_key_registry_a_test.dart`
- Create: `lib/data/ssh/ssh_key_registry_a.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/ssh/ssh_key_registry_a_test.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lk_ssh/data/ssh/ssh_key_registry_a.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/core/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecure extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecure secure;
  late SshKeyRegistryA registry;

  setUp(() {
    secure = _MockSecure();
    registry = SshKeyRegistryA.forTest(secure);
  });

  test('save writes bytes under key_<id> and passphrase under pp_<id>', () async {
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    await registry.save(keyId: 'k1', bytes: bytes, passphrase: 'secret');
    verify(() => secure.write(key: 'key_k1', value: base64Encode(bytes))).called(1);
    verify(() => secure.write(key: 'pp_k1', value: 'secret')).called(1);
  });

  test('save without passphrase still erases any previous one', () async {
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await registry.save(keyId: 'k2', bytes: Uint8List.fromList([9]));
    verify(() => secure.delete(key: 'pp_k2')).called(1);
  });

  test('loadBytes returns SecureKey when present', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => secure.read(key: 'key_k1'))
        .thenAnswer((_) async => base64Encode(bytes));
    final r = await registry.loadBytes('k1');
    expect(r, isA<Ok>());
    final ok = r as Ok;
    expect(ok.value.bytes, bytes);
  });

  test('loadBytes returns KeyNotFoundError when absent', () async {
    when(() => secure.read(key: 'key_missing')).thenAnswer((_) async => null);
    final r = await registry.loadBytes('missing');
    expect(r, isA<Err>());
    expect((r as Err).error, isA<KeyNotFoundError>());
  });

  test('loadPassphrase returns null when not stored', () async {
    when(() => secure.read(key: 'pp_k1')).thenAnswer((_) async => null);
    expect(await registry.loadPassphrase('k1'), null);
  });

  test('delete removes both key and passphrase entries', () async {
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await registry.delete('k1');
    verify(() => secure.delete(key: 'key_k1')).called(1);
    verify(() => secure.delete(key: 'pp_k1')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/ssh/ssh_key_registry_a_test.dart`
Expected: FAIL — class missing.

- [ ] **Step 3: Write the implementation**

```dart
// lib/data/ssh/ssh_key_registry_a.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import 'i_ssh_key_registry.dart';

final class SshKeyRegistryA implements ISshKeyRegistry {
  SshKeyRegistryA()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  SshKeyRegistryA.forTest(this._storage);

  final FlutterSecureStorage _storage;

  String _keyName(String id) => 'key_$id';
  String _ppName(String id) => 'pp_$id';

  @override
  Future<Result<void, AppError>> save({
    required String keyId,
    required Uint8List bytes,
    String? passphrase,
  }) async {
    try {
      await _storage.write(key: _keyName(keyId), value: base64Encode(bytes));
      if (passphrase == null) {
        await _storage.delete(key: _ppName(keyId));
      } else {
        await _storage.write(key: _ppName(keyId), value: passphrase);
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<SecureKey, AppError>> loadBytes(String keyId) async {
    try {
      final raw = await _storage.read(key: _keyName(keyId));
      if (raw == null) return const Err(KeyNotFoundError());
      return Ok(SecureKey.fromBytes(base64Decode(raw)));
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<String?> loadPassphrase(String keyId) =>
      _storage.read(key: _ppName(keyId));

  @override
  Future<Result<void, AppError>> delete(String keyId) async {
    try {
      await _storage.delete(key: _keyName(keyId));
      await _storage.delete(key: _ppName(keyId));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }
}
```

- [ ] **Step 4: Run test + analyze**

Run: `flutter test test/data/ssh/ssh_key_registry_a_test.dart && flutter analyze --fatal-infos`
Expected: 6/6 PASS, clean.

- [ ] **Step 5: Commit**

```bash
git add lib/data/ssh/ssh_key_registry_a.dart test/data/ssh/ssh_key_registry_a_test.dart
git commit -m "feat: SshKeyRegistryA (mode A multi-keys via FlutterSecureStorage)"
```

---

### Task 2.5: `SshKeyRegistryD` — vault Argon2id + AES-GCM

**Files:**
- Test: `test/data/ssh/ssh_key_registry_d_test.dart`
- Create: `lib/data/ssh/ssh_key_registry_d.dart`

**Approach:** the vault is a single binary file `<docs>/key_vault.bin` containing `[salt(32 bytes)][nonce+ciphertext+mac]`. The plaintext is `jsonEncode({keyId: {"bytes": <base64>, "passphrase": <string?>}})`. Argon2id parameters MUST match `SecureKeyStorageD` (`memory: 65536, parallelism: 2, iterations: 3, hashLength: 32`) so the user's existing passphrase derives a key compatible with the same KDF cost.

The constructor takes the passphrase. Each `save`/`load` call re-derives the key from the salt (Argon2id is the bottleneck — ~50ms per call on a phone). Acceptable for P1 since key access is rare (once per SSH connection). Optimization (cache derived key in memory keyed by salt) deferred.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/ssh/ssh_key_registry_d_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/core/result.dart';
import 'package:lk_ssh/data/ssh/ssh_key_registry_d.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lk_ssh_kd_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('save then loadBytes returns the same bytes (same passphrase)', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp1');
    final bytes = Uint8List.fromList(List.generate(64, (i) => i));
    final saveR = await reg.save(keyId: 'k1', bytes: bytes);
    expect(saveR, isA<Ok<void, AppError>>());

    final reg2 = SshKeyRegistryD(directory: tmp, passphrase: 'pp1');
    final r = await reg2.loadBytes('k1');
    switch (r) {
      case Ok(:final value): expect(value.bytes, bytes);
      case Err(): fail('expected Ok');
    }
  });

  test('wrong passphrase returns KeyDecryptionError', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'good');
    await reg.save(keyId: 'k1', bytes: Uint8List.fromList([1, 2, 3]));

    final reg2 = SshKeyRegistryD(directory: tmp, passphrase: 'wrong');
    final r = await reg2.loadBytes('k1');
    expect(r, isA<Err<dynamic, AppError>>());
    switch (r) {
      case Err(:final error): expect(error, isA<KeyDecryptionError>());
      case Ok(): fail('expected Err');
    }
  });

  test('multiple keys in same vault', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'a', bytes: Uint8List.fromList([1]));
    await reg.save(keyId: 'b', bytes: Uint8List.fromList([2]));
    final ra = await reg.loadBytes('a');
    final rb = await reg.loadBytes('b');
    switch (ra) { case Ok(:final value): expect(value.bytes, [1]); case Err(): fail('a'); }
    switch (rb) { case Ok(:final value): expect(value.bytes, [2]); case Err(): fail('b'); }
  });

  test('passphrase round-trip', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'k', bytes: Uint8List.fromList([0]), passphrase: 'inner-pp');
    expect(await reg.loadPassphrase('k'), 'inner-pp');
  });

  test('delete removes the entry', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'k', bytes: Uint8List.fromList([1]));
    await reg.delete('k');
    final r = await reg.loadBytes('k');
    expect(r, isA<Err<dynamic, AppError>>());
  });

  test('loadBytes on missing keyId returns KeyNotFoundError', () async {
    final reg = SshKeyRegistryD(directory: tmp, passphrase: 'pp');
    await reg.save(keyId: 'k', bytes: Uint8List.fromList([1]));
    final r = await reg.loadBytes('other');
    switch (r) {
      case Err(:final error): expect(error, isA<KeyNotFoundError>());
      case Ok(): fail('expected Err');
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/ssh/ssh_key_registry_d_test.dart`
Expected: FAIL — class missing.

- [ ] **Step 3: Write the implementation**

```dart
// lib/data/ssh/ssh_key_registry_d.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import 'i_ssh_key_registry.dart';

final class SshKeyRegistryD implements ISshKeyRegistry {
  SshKeyRegistryD({required Directory directory, required String passphrase})
      : _file = File('${directory.path}/key_vault.bin'),
        _passphrase = passphrase;

  final File _file;
  final String _passphrase;

  // Same parameters as SecureKeyStorageD — keep the user passphrase compatible.
  static final _argon2id = Argon2id(
    memory: 65536,
    parallelism: 2,
    iterations: 3,
    hashLength: 32,
  );
  static const _saltLen = 32;

  Future<SecretKey> _deriveKey(List<int> salt) =>
      _argon2id.deriveKey(
        secretKey: SecretKey(utf8.encode(_passphrase)),
        nonce: salt,
      );

  Uint8List _randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
  }

  /// Returns null if the vault doesn't exist.
  /// Returns Err(KeyDecryptionError) if it exists but the passphrase is wrong.
  Future<Result<Map<String, Map<String, dynamic>>, AppError>> _loadVault() async {
    if (!await _file.exists()) return const Ok(<String, Map<String, dynamic>>{});
    try {
      final raw = await _file.readAsBytes();
      if (raw.length <= _saltLen) return const Err(KeyDecryptionError());
      final salt = raw.sublist(0, _saltLen);
      final blob = raw.sublist(_saltLen);
      final aesGcm = AesGcm.with256bits();
      final box = SecretBox.fromConcatenation(
        blob,
        nonceLength: aesGcm.nonceLength,
        macLength: aesGcm.macAlgorithm.macLength,
      );
      final secretKey = await _deriveKey(salt);
      final decrypted = await aesGcm.decrypt(box, secretKey: secretKey);
      final json = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      return Ok(json.map((k, v) => MapEntry(k, (v as Map).cast<String, dynamic>())));
    } on SecretBoxAuthenticationError {
      return const Err(KeyDecryptionError());
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  Future<Result<void, AppError>> _writeVault(Map<String, Map<String, dynamic>> vault) async {
    try {
      final salt = _randomBytes(_saltLen);
      final secretKey = await _deriveKey(salt);
      final aesGcm = AesGcm.with256bits();
      final plaintext = utf8.encode(jsonEncode(vault));
      final box = await aesGcm.encrypt(plaintext, secretKey: secretKey);
      final blob = Uint8List.fromList([...salt, ...box.concatenation()]);
      // Atomic write: tmp then rename.
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsBytes(blob, flush: true);
      await tmp.rename(_file.path);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> save({
    required String keyId,
    required Uint8List bytes,
    String? passphrase,
  }) async {
    final loaded = await _loadVault();
    if (loaded is Err<Map<String, Map<String, dynamic>>, AppError>) {
      return Err(loaded.error);
    }
    final vault = (loaded as Ok<Map<String, Map<String, dynamic>>, AppError>).value;
    final next = Map<String, Map<String, dynamic>>.from(vault);
    next[keyId] = {
      'bytes': base64Encode(bytes),
      if (passphrase != null) 'passphrase': passphrase,
    };
    return _writeVault(next);
  }

  @override
  Future<Result<SecureKey, AppError>> loadBytes(String keyId) async {
    final loaded = await _loadVault();
    switch (loaded) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        final entry = value[keyId];
        if (entry == null) return const Err(KeyNotFoundError());
        final bytes = base64Decode(entry['bytes'] as String);
        return Ok(SecureKey.fromBytes(bytes));
    }
  }

  @override
  Future<String?> loadPassphrase(String keyId) async {
    final loaded = await _loadVault();
    switch (loaded) {
      case Err():
        return null;
      case Ok(:final value):
        return value[keyId]?['passphrase'] as String?;
    }
  }

  @override
  Future<Result<void, AppError>> delete(String keyId) async {
    final loaded = await _loadVault();
    if (loaded is Err<Map<String, Map<String, dynamic>>, AppError>) {
      return Err(loaded.error);
    }
    final vault = (loaded as Ok<Map<String, Map<String, dynamic>>, AppError>).value;
    if (!vault.containsKey(keyId)) return const Ok(null);
    final next = Map<String, Map<String, dynamic>>.from(vault)..remove(keyId);
    return _writeVault(next);
  }
}
```

- [ ] **Step 4: Run test + analyze**

Run: `flutter test test/data/ssh/ssh_key_registry_d_test.dart && flutter analyze --fatal-infos`
Expected: 6/6 PASS, clean. The Argon2id derivation is slow (~50–200ms per op depending on device); on CI this may take a few seconds total — acceptable.

> Note: existing `secure_key_storage_d_test.dart` MUST still pass — the legacy mode D continues to work for the v1 single-key flow during migration.

- [ ] **Step 5: Commit**

```bash
git add lib/data/ssh/ssh_key_registry_d.dart test/data/ssh/ssh_key_registry_d_test.dart
git commit -m "feat: SshKeyRegistryD (mode D multi-keys via Argon2id+AES-GCM vault)"
```

---

### Task 2.6: Extend `IStorageService` and `JsonStorageService` for `SshKey` list

**Files:**
- Modify: `lib/data/storage/i_storage_service.dart`
- Modify: `lib/data/storage/json_storage_service.dart`

- [ ] **Step 1: Add interface methods**

```dart
// in lib/data/storage/i_storage_service.dart, add at the bottom of the interface body
Future<Result<List<SshKey>, StorageError>> loadSshKeys();
Future<Result<void, StorageError>> saveSshKeys(List<SshKey> keys);
```

Don't forget the import:
```dart
import '../models/ssh_key.dart';
```

- [ ] **Step 2: Implement in `JsonStorageService`**

```dart
// in lib/data/storage/json_storage_service.dart, add the import
import '../models/ssh_key.dart';

// add at the end of the class
@override
Future<Result<List<SshKey>, StorageError>> loadSshKeys() =>
    _loadList('ssh_keys', SshKey.fromJson);

@override
Future<Result<void, StorageError>> saveSshKeys(List<SshKey> keys) =>
    _saveList('ssh_keys', keys, (k) => k.toJson());
```

- [ ] **Step 3: Verify existing `JsonStorageService` test still passes; add coverage**

Append to `test/data/storage/json_storage_service_test.dart` a test for the round-trip of `SshKey`. Mirror an existing test structure (snippets/categories). Then run:
`flutter test test/data/storage/json_storage_service_test.dart && flutter analyze --fatal-infos`
Expected: PASS + clean.

- [ ] **Step 4: Commit**

```bash
git add lib/data/storage/i_storage_service.dart lib/data/storage/json_storage_service.dart test/data/storage/json_storage_service_test.dart
git commit -m "feat: persist SshKey list via IStorageService.loadSshKeys/saveSshKeys"
```

---

### Task 2.7: Migration `P1AuthMigration` (test first)

**Files:**
- Test: `test/data/migration/p1_auth_migration_test.dart`
- Create: `lib/data/migration/p1_auth_migration.dart`

The migration reads `Settings.migrationP1Done`. If false **and** `legacyKey` exists, it: (1) saves a `SshKey(id="default", label="Clé par défaut", addedAt=now)`, (2) writes legacy bytes to the registry under `id="default"`, (3) updates every `Server` to `authMethod=key, keyId="default"`, (4) writes a backup `servers.json.pre-p1`, (5) sets the flag.

- [ ] **Step 1: Write the failing test (mocked dependencies)**

```dart
// test/data/migration/p1_auth_migration_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/core/errors.dart';
import 'package:lk_ssh/core/result.dart';
import 'package:lk_ssh/core/secure_key.dart';
import 'package:lk_ssh/data/migration/p1_auth_migration.dart';
import 'package:lk_ssh/data/models/auth_method.dart';
import 'package:lk_ssh/data/models/server.dart';
import 'package:lk_ssh/data/models/settings.dart';
import 'package:lk_ssh/data/models/ssh_key.dart';
import 'package:lk_ssh/data/ssh/i_ssh_key_registry.dart';
import 'package:lk_ssh/data/storage/i_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements IStorageService {}
class _MockRegistry extends Mock implements ISshKeyRegistry {}
class _MockLegacy extends Mock implements LegacyKeyReader {}

void main() {
  setUpAll(() {
    registerFallbackValue(<Server>[]);
    registerFallbackValue(<SshKey>[]);
    registerFallbackValue(const Settings());
    registerFallbackValue(Uint8List(0));
  });

  late _MockStorage storage;
  late _MockRegistry registry;
  late _MockLegacy legacy;

  setUp(() {
    storage = _MockStorage();
    registry = _MockRegistry();
    legacy = _MockLegacy();
  });

  test('skips when migrationP1Done is already true', () async {
    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings(migrationP1Done: true)));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();

    verifyNever(() => storage.saveServers(any()));
    verifyNever(() => storage.saveSshKeys(any()));
    verifyNever(() => registry.save(keyId: any(named: 'keyId'), bytes: any(named: 'bytes')));
  });

  test('skips and sets flag when no legacy key exists', () async {
    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings()));
    when(() => legacy.hasKey()).thenAnswer((_) async => false);
    when(() => storage.saveSettings(any())).thenAnswer((_) async => const Ok(null));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();

    verify(() => storage.saveSettings(
        any(that: predicate<Settings>((s) => s.migrationP1Done)))).called(1);
    verifyNever(() => registry.save(keyId: any(named: 'keyId'), bytes: any(named: 'bytes')));
  });

  test('migrates: creates default SshKey, registers bytes, retags servers', () async {
    final servers = [
      const Server(id: 's1', label: 'a', host: 'h', username: 'u'),
      const Server(id: 's2', label: 'b', host: 'h2', username: 'u'),
    ];
    final bytes = Uint8List.fromList([1, 2, 3]);

    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings()));
    when(() => legacy.hasKey()).thenAnswer((_) async => true);
    when(() => legacy.loadKey()).thenAnswer((_) async => Ok(SecureKey.fromBytes(bytes)));
    when(() => storage.loadServers()).thenAnswer((_) async => Ok(servers));
    when(() => storage.loadSshKeys()).thenAnswer((_) async => const Ok([]));
    when(() => storage.saveSshKeys(any())).thenAnswer((_) async => const Ok(null));
    when(() => storage.saveServers(any())).thenAnswer((_) async => const Ok(null));
    when(() => storage.saveSettings(any())).thenAnswer((_) async => const Ok(null));
    when(() => registry.save(
            keyId: any(named: 'keyId'),
            bytes: any(named: 'bytes'),
            passphrase: any(named: 'passphrase')))
        .thenAnswer((_) async => const Ok(null));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();

    final savedKeys = verify(() => storage.saveSshKeys(captureAny())).captured.single as List<SshKey>;
    expect(savedKeys, hasLength(1));
    expect(savedKeys.first.id, 'default');
    expect(savedKeys.first.label, 'Clé par défaut');

    verify(() => registry.save(keyId: 'default', bytes: bytes)).called(1);

    final savedServers = verify(() => storage.saveServers(captureAny())).captured.single as List<Server>;
    expect(savedServers.every((s) => s.authMethod == AuthMethod.key && s.keyId == 'default'), isTrue);

    verify(() => storage.saveSettings(
        any(that: predicate<Settings>((s) => s.migrationP1Done)))).called(1);
  });

  test('idempotent: running twice is a no-op the second time', () async {
    when(() => storage.loadSettings())
        .thenAnswer((_) async => const Ok(Settings(migrationP1Done: true)));

    final mig = P1AuthMigration(storage: storage, registry: registry, legacy: legacy);
    await mig.run();
    await mig.run();
    verifyNever(() => storage.saveServers(any()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/migration/p1_auth_migration_test.dart`
Expected: FAIL — class missing.

- [ ] **Step 3: Write the migration**

The migration is mode-agnostic from the migration's perspective: it reads the legacy key (the `LegacyKeyReader` interface abstracts away whether mode A or D is providing it — see Task 4.0c where `LegacyKeyReaderImpl.modeD(...)` injects the passphrase). The migration only fails if `legacy.loadKey()` returns Err, which the bootstrap prevents by gating mode D behind `UnlockScreen`.

```dart
// lib/data/migration/p1_auth_migration.dart
import '../../core/errors.dart';
import '../../core/result.dart';
import '../../core/secure_key.dart';
import '../models/auth_method.dart';
import '../models/server.dart';
import '../models/ssh_key.dart';
import '../ssh/i_secure_key_storage.dart';
import '../ssh/i_ssh_key_registry.dart';
import '../storage/i_storage_service.dart';

abstract interface class LegacyKeyReader {
  Future<bool> hasKey();
  Future<Result<SecureKey, AppError>> loadKey();
}

final class LegacyKeyReaderImpl implements LegacyKeyReader {
  LegacyKeyReaderImpl(this._storage) : _passphrase = null;
  LegacyKeyReaderImpl.modeD(this._storage, String passphrase)
      : _passphrase = passphrase;

  final ISecureKeyStorage _storage;
  final String? _passphrase;

  @override
  Future<bool> hasKey() => _storage.hasKey();

  @override
  Future<Result<SecureKey, AppError>> loadKey() =>
      _storage.loadKey(passphrase: _passphrase);
}

class P1AuthMigration {
  P1AuthMigration({
    required this.storage,
    required this.registry,
    required this.legacy,
  });

  final IStorageService storage;
  final ISshKeyRegistry registry;
  final LegacyKeyReader legacy;

  static const defaultKeyId = 'default';

  Future<void> run() async {
    final settingsR = await storage.loadSettings();
    final settings = switch (settingsR) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (settings == null || settings.migrationP1Done) return;

    if (!await legacy.hasKey()) {
      await storage.saveSettings(settings.copyWith(migrationP1Done: true));
      return;
    }

    final keyR = await legacy.loadKey();
    final secureKey = switch (keyR) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (secureKey == null) return; // bootstrap should have unlocked; retry next boot.

    final saveBytes = await registry.save(
      keyId: defaultKeyId,
      bytes: secureKey.bytes,
    );
    if (saveBytes is Err) return;

    final keys = switch (await storage.loadSshKeys()) {
      Ok(:final value) => value,
      Err() => <SshKey>[],
    };
    if (!keys.any((k) => k.id == defaultKeyId)) {
      await storage.saveSshKeys([
        ...keys,
        SshKey(
          id: defaultKeyId,
          label: 'Clé par défaut',
          addedAt: DateTime.now(),
        ),
      ]);
    }

    final serversR = await storage.loadServers();
    if (serversR case Ok(:final value)) {
      final retagged = value
          .map((s) =>
              s.copyWith(authMethod: AuthMethod.key, keyId: defaultKeyId))
          .toList();
      await storage.saveServers(retagged);
    }

    await storage.saveSettings(settings.copyWith(migrationP1Done: true));
  }
}
```

> Note: `secureKey.bytes` is read once. The migration intentionally does not zeroize because the bytes are immediately re-stored and dropped at end of scope.

- [ ] **Step 4: Run test + analyze**

Run: `flutter test test/data/migration/p1_auth_migration_test.dart && flutter analyze --fatal-infos`
Expected: 4/4 PASS, clean.

- [ ] **Step 5: Wiring is in Task 4.0c**

The bootstrap orchestration (constructing `P1AuthMigration` with the right registry+legacy reader and running it post-unlock) lives in Task 4.0c — see `main.dart` there. This task only delivers the migration logic and its tests.

- [ ] **Step 6: Commit**

```bash
git add lib/data/migration/p1_auth_migration.dart test/data/migration/p1_auth_migration_test.dart
git commit -m "feat: P1AuthMigration — convert legacy key into SshKey 'default'"
```

---

## Step 3 — Auth layer + HostKeyVerifier

### Task 3.1: `AuthCredentials` sealed class + `HostKeyDecision`/`HostKeyChange`/`AuthPromptRequest`

**Files:**
- Create: `lib/data/models/auth_credentials.dart`
- Create: `lib/data/models/auth_prompt_request.dart`

- [ ] **Step 1: Write `auth_credentials.dart`**

```dart
// lib/data/models/auth_credentials.dart
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

sealed class AuthCredentials {
  const AuthCredentials();
}

final class KeyCreds extends AuthCredentials {
  KeyCreds({required this.bytes, this.passphrase});
  final Uint8List bytes;
  final String? passphrase;
}

final class PasswordCreds extends AuthCredentials {
  const PasswordCreds(this.password);
  final String password;
}

final class InteractiveCreds extends AuthCredentials {
  InteractiveCreds(this.onPrompt);
  final Future<List<String>?> Function(SSHUserInfoRequest) onPrompt;
}
```

- [ ] **Step 2: Write `auth_prompt_request.dart`**

```dart
// lib/data/models/auth_prompt_request.dart
import 'dart:async';

import 'package:dartssh2/dartssh2.dart';

sealed class AuthPromptRequest {
  const AuthPromptRequest();
}

final class PasswordPromptRequest extends AuthPromptRequest {
  PasswordPromptRequest({required this.user, required this.host});
  final String user;
  final String host;
  final Completer<String?> completer = Completer<String?>();
}

final class KbInteractivePromptRequest extends AuthPromptRequest {
  KbInteractivePromptRequest(this.request);
  final SSHUserInfoRequest request;
  final Completer<List<String>?> completer = Completer<List<String>?>();
}

final class HostKeyMismatchRequest extends AuthPromptRequest {
  HostKeyMismatchRequest(this.change);
  final HostKeyChange change;
  final Completer<HostKeyDecision> completer = Completer<HostKeyDecision>();
}

enum HostKeyDecision { reject, acceptOnce, acceptAndPin }

class HostKeyChange {
  const HostKeyChange({
    required this.host,
    required this.port,
    required this.oldFingerprint,
    required this.newFingerprint,
  });
  final String host;
  final int port;
  final String oldFingerprint;
  final String newFingerprint;
}
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/data/models/auth_credentials.dart lib/data/models/auth_prompt_request.dart
git commit -m "feat: sealed AuthCredentials + AuthPromptRequest types"
```

---

### Task 3.2: `HostKeyVerifier` (test first)

**Files:**
- Test: `test/domain/services/host_key_verifier_test.dart`
- Create: `lib/domain/services/host_key_verifier.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/services/host_key_verifier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/auth_prompt_request.dart';
import 'package:lk_ssh/data/storage/i_known_hosts_storage.dart';
import 'package:lk_ssh/domain/services/host_key_verifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements IKnownHostsStorage {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
  });

  test('unknown host: auto-pin and accept', () async {
    when(() => storage.load('h', 22)).thenAnswer((_) async => null);
    when(() => storage.save('h', 22, 'fp-new')).thenAnswer((_) async {});
    final v = HostKeyVerifier(
      storage: storage,
      onMismatch: (_) async => HostKeyDecision.reject,
    );
    final ok = await v.verify(host: 'h', port: 22, fingerprintSha256: 'fp-new');
    expect(ok, true);
    verify(() => storage.save('h', 22, 'fp-new')).called(1);
  });

  test('matching fingerprint: accept without re-saving', () async {
    when(() => storage.load('h', 22)).thenAnswer((_) async => 'fp');
    final v = HostKeyVerifier(
      storage: storage,
      onMismatch: (_) async => HostKeyDecision.reject,
    );
    final ok = await v.verify(host: 'h', port: 22, fingerprintSha256: 'fp');
    expect(ok, true);
    verifyNever(() => storage.save(any(), any(), any()));
  });

  group('mismatch', () {
    setUp(() {
      when(() => storage.load('h', 22)).thenAnswer((_) async => 'old-fp');
    });

    test('reject decision returns false, no save', () async {
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (_) async => HostKeyDecision.reject,
      );
      final ok = await v.verify(host: 'h', port: 22, fingerprintSha256: 'new-fp');
      expect(ok, false);
      verifyNever(() => storage.save(any(), any(), any()));
    });

    test('acceptOnce returns true, no save', () async {
      when(() => storage.save(any(), any(), any())).thenAnswer((_) async {});
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (_) async => HostKeyDecision.acceptOnce,
      );
      final ok = await v.verify(host: 'h', port: 22, fingerprintSha256: 'new-fp');
      expect(ok, true);
      verifyNever(() => storage.save(any(), any(), any()));
    });

    test('acceptAndPin returns true, saves new fp', () async {
      when(() => storage.save('h', 22, 'new-fp')).thenAnswer((_) async {});
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (_) async => HostKeyDecision.acceptAndPin,
      );
      final ok = await v.verify(host: 'h', port: 22, fingerprintSha256: 'new-fp');
      expect(ok, true);
      verify(() => storage.save('h', 22, 'new-fp')).called(1);
    });

    test('mismatch handler receives both fingerprints', () async {
      HostKeyChange? captured;
      final v = HostKeyVerifier(
        storage: storage,
        onMismatch: (change) async {
          captured = change;
          return HostKeyDecision.reject;
        },
      );
      await v.verify(host: 'h', port: 22, fingerprintSha256: 'new-fp');
      expect(captured?.oldFingerprint, 'old-fp');
      expect(captured?.newFingerprint, 'new-fp');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/services/host_key_verifier_test.dart`
Expected: FAIL — class missing.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/services/host_key_verifier.dart
import '../../data/models/auth_prompt_request.dart';
import '../../data/storage/i_known_hosts_storage.dart';

class HostKeyVerifier {
  HostKeyVerifier({
    required this.storage,
    required this.onMismatch,
  });

  final IKnownHostsStorage storage;
  final Future<HostKeyDecision> Function(HostKeyChange) onMismatch;

  Future<bool> verify({
    required String host,
    required int port,
    required String fingerprintSha256,
  }) async {
    final known = await storage.load(host, port);
    if (known == null) {
      // F1a — auto-pin on first connection.
      await storage.save(host, port, fingerprintSha256);
      return true;
    }
    if (known == fingerprintSha256) return true;

    final decision = await onMismatch(HostKeyChange(
      host: host,
      port: port,
      oldFingerprint: known,
      newFingerprint: fingerprintSha256,
    ));
    switch (decision) {
      case HostKeyDecision.reject:
        return false;
      case HostKeyDecision.acceptOnce:
        return true;
      case HostKeyDecision.acceptAndPin:
        await storage.save(host, port, fingerprintSha256);
        return true;
    }
  }
}
```

- [ ] **Step 4: Run test + analyze**

Run: `flutter test test/domain/services/host_key_verifier_test.dart && flutter analyze --fatal-infos`
Expected: 5/5 PASS, clean.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/host_key_verifier.dart test/domain/services/host_key_verifier_test.dart
git commit -m "feat: HostKeyVerifier (TOFU + mismatch handler)"
```

---

### Task 3.3: Refactor `SshClientFactory.connect` to use `AuthCredentials` + `HostKeyVerifier`

**Files:**
- Modify: `lib/domain/services/ssh_service.dart`
- Test: extend `test/domain/services/ssh_service_test.dart` or create `test/domain/services/ssh_service_authmethod_test.dart`

dartssh2 `SSHClient` accepts:
- `identities` — list of `SSHKeyPair`
- `onPasswordRequest` — `FutureOr<String?> Function()`
- `onUserInfoRequest` — `FutureOr<List<String>?> Function(SSHUserInfoRequest)`
- `onVerifyHostKey` — `FutureOr<bool> Function(String type, Uint8List key)`

The fingerprint we expose is `sha256` of the host key bytes, base64-encoded (matches the OpenSSH convention `SHA256:<base64>`).

- [ ] **Step 1: Write the new test**

```dart
// test/domain/services/ssh_service_authmethod_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/data/models/auth_credentials.dart';
import 'package:lk_ssh/data/models/server.dart';
import 'package:lk_ssh/domain/services/ssh_service.dart';
import 'package:lk_ssh/domain/services/host_key_verifier.dart';
import 'package:lk_ssh/data/storage/i_known_hosts_storage.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements SSHClient {}
class _MockKnownHosts extends Mock implements IKnownHostsStorage {}

class _RecordingFactory implements SshClientFactory {
  AuthCredentials? capturedCreds;
  HostKeyVerifier? capturedVerifier;
  @override
  Future<SSHClient> connect({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  }) async {
    capturedCreds = credentials;
    capturedVerifier = verifier;
    final c = _MockClient();
    when(() => c.authenticated).thenAnswer((_) async {});
    return c;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  test('SshClientFactory.connect new signature accepts AuthCredentials + verifier', () async {
    final factory = _RecordingFactory();
    final svc = SSHService(factory);
    final verifier = HostKeyVerifier(
      storage: _MockKnownHosts(),
      onMismatch: (_) async => throw UnimplementedError(),
    );
    final r = await svc.connectWith(
      server: const Server(id: 's', label: 's', host: 'h', username: 'u'),
      credentials: const PasswordCreds('hunter2'),
      verifier: verifier,
    );
    expect(r.isOk, true);
    expect(factory.capturedCreds, isA<PasswordCreds>());
    expect(factory.capturedVerifier, verifier);
  });
}
```

> Add a tiny extension or helper on `Result` if `isOk` doesn't exist — or compare against `Ok` directly.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/services/ssh_service_authmethod_test.dart`
Expected: FAIL — `SshClientFactory` signature mismatch.

- [ ] **Step 3: Refactor `ssh_service.dart`**

Replace the file with:

```dart
// lib/domain/services/ssh_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dartssh2/dartssh2.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/auth_credentials.dart';
import '../../data/models/server.dart';
import '../../data/storage/debug_log_service.dart';
import 'host_key_verifier.dart';

abstract interface class SshClientFactory {
  Future<SSHClient> connect({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  });
}

final class DefaultSshClientFactory implements SshClientFactory {
  static const _connectTimeout = Duration(seconds: 15);
  static const _authTimeout = Duration(seconds: 20);

  @override
  Future<SSHClient> connect({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  }) async {
    final socket = await SSHSocket.connect(server.host, server.port)
        .timeout(_connectTimeout);

    Future<bool> verifyHost(String type, Uint8List keyBytes) async {
      final hash = await Sha256().hash(keyBytes);
      final fp = base64.encode(hash.bytes);
      return verifier.verify(
        host: server.host,
        port: server.port,
        fingerprintSha256: fp,
      );
    }

    final client = switch (credentials) {
      KeyCreds(:final bytes, :final passphrase) => SSHClient(
          socket,
          username: server.username,
          identities: SSHKeyPair.fromPem(
            String.fromCharCodes(bytes),
            passphrase,
          ),
          keepAliveInterval: const Duration(seconds: 30),
          onVerifyHostKey: verifyHost,
        ),
      PasswordCreds(:final password) => SSHClient(
          socket,
          username: server.username,
          onPasswordRequest: () => password,
          keepAliveInterval: const Duration(seconds: 30),
          onVerifyHostKey: verifyHost,
        ),
      InteractiveCreds(:final onPrompt) => SSHClient(
          socket,
          username: server.username,
          onUserInfoRequest: (req) => onPrompt(req),
          keepAliveInterval: const Duration(seconds: 30),
          onVerifyHostKey: verifyHost,
        ),
    };
    await client.authenticated.timeout(_authTimeout);
    return client;
  }
}

final class SshConnection {
  SshConnection({required this.client, required this.server});

  final SSHClient client;
  final Server server;
  SSHSession? _activeShell;

  Future<Result<SSHSession, AppError>> openShell({
    int width = 80,
    int height = 24,
  }) async {
    final log = DebugLogService.instance;
    log.log('SSH', 'openShell(width=$width, height=$height) — _activeShell avant: ${_activeShell == null ? "null" : "non-null"}');
    try {
      final shell = await client.shell(
        pty: SSHPtyConfig(width: width, height: height),
      );
      _activeShell = shell;
      log.log('SSH', 'openShell OK — _activeShell défini');
      return Ok(shell);
    } catch (e) {
      log.log('SSH', 'openShell ERREUR: $e');
      return Err(SshConnectionError(e.toString()));
    }
  }

  void sendCommand(String command) {
    final log = DebugLogService.instance;
    log.log('SSH', 'sendCommand("$command") — _activeShell: ${_activeShell == null ? "NULL ← PROBLÈME" : "OK"}');
    _activeShell?.write(Uint8List.fromList(utf8.encode('$command\n')));
  }

  void sendRaw(Uint8List bytes) {
    final log = DebugLogService.instance;
    log.log('SSH', 'sendRaw(${bytes.length} bytes) — _activeShell: ${_activeShell == null ? "NULL ← PROBLÈME" : "OK"}');
    _activeShell?.write(bytes);
  }

  void close() => client.close();
}

final class SSHService {
  SSHService([SshClientFactory? factory])
      : _factory = factory ?? DefaultSshClientFactory();

  final SshClientFactory _factory;

  Future<Result<SshConnection, AppError>> connectWith({
    required Server server,
    required AuthCredentials credentials,
    required HostKeyVerifier verifier,
  }) async {
    try {
      final client = await _factory.connect(
        server: server,
        credentials: credentials,
        verifier: verifier,
      );
      return Ok(SshConnection(client: client, server: server));
    } on SSHAuthFailError catch (e) {
      return Err(SshAuthError(e.toString()));
    } on TimeoutException {
      return const Err(SshConnectionError(
          'Délai dépassé — serveur injoignable ou authentification trop lente.'));
    } catch (e) {
      return Err(SshConnectionError(e.toString()));
    }
  }
}
```

> The old `SSHService.connect(server:, privateKey:)` is removed. Callers must migrate to `connectWith`. The next task adapts `sshNotifier`.

- [ ] **Step 4: Update existing `ssh_service_test.dart`**

The existing test `test/domain/services/ssh_service_test.dart` tests the v1 signature. Update it to use the new `connectWith` with `KeyCreds` so tests still pass. Run:
`flutter test test/domain/services/ && flutter analyze --fatal-infos`
Expected: all PASS, clean.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/ssh_service.dart test/domain/services/ssh_service_authmethod_test.dart test/domain/services/ssh_service_test.dart
git commit -m "feat: refactor SshClientFactory around AuthCredentials + HostKeyVerifier"
```

---

## Step 4 — Riverpod providers + boot unlock for mode D

### Task 4.0a: `vaultPassphraseProvider` (in-memory holder for mode D)

**Files:**
- Create: `lib/presentation/providers/vault_passphrase_provider.dart`

This provider holds the user passphrase in memory after a successful unlock. It is `keepAlive: true` (do NOT autoDispose — losing the passphrase mid-session would force a re-unlock on every screen change). The state is `String?`; null means "locked", non-null means "unlocked".

- [ ] **Step 1: Write the provider**

```dart
// lib/presentation/providers/vault_passphrase_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_passphrase_provider.g.dart';

@Riverpod(keepAlive: true)
class VaultPassphrase extends _$VaultPassphrase {
  @override
  String? build() => null;

  void unlock(String passphrase) => state = passphrase;
  void lock() => state = null;
}
```

- [ ] **Step 2: Regenerate + analyze**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/providers/vault_passphrase_provider.dart lib/presentation/providers/vault_passphrase_provider.g.dart
git commit -m "feat: vaultPassphraseProvider (in-memory unlock state)"
```

---

### Task 4.0b: `UnlockScreen`

**Files:**
- Create: `lib/presentation/screens/unlock_screen.dart`

The screen takes a `verifyPassphrase: Future<bool> Function(String)` callback so it doesn't hard-code the verification logic. The bootstrap (Task 4.0c) builds this callback by trying to decrypt the vault (via `SshKeyRegistryD`) or, if no vault exists yet, the legacy mode-D key (via `SecureKeyStorageD`). Wrong passphrase → re-prompt.

- [ ] **Step 1: Write the screen**

```dart
// lib/presentation/screens/unlock_screen.dart
import 'package:flutter/material.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, required this.onSubmit});

  /// Called with the typed passphrase. Returns true to proceed (passphrase
  /// is correct), false to re-prompt with an error. The bootstrap builds
  /// this callback after testing the passphrase against the vault/legacy.
  final Future<bool> Function(String passphrase) onSubmit;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.isEmpty) {
      setState(() => _error = 'Passphrase requise.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.onSubmit(_ctrl.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Passphrase incorrecte.';
        _ctrl.clear();
      });
    }
    // On success the bootstrap replaces this route — no need to setState here.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                Text('LK-SSH',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Mode chiffré — entre la passphrase pour déverrouiller tes clés.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _ctrl,
                  obscureText: true,
                  autofocus: true,
                  enabled: !_busy,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Passphrase',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Déverrouiller'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze + commit**

```bash
flutter analyze --fatal-infos
git add lib/presentation/screens/unlock_screen.dart
git commit -m "feat: UnlockScreen for mode D boot-time passphrase entry"
```

---

### Task 4.0c: Bootstrap orchestration in `main.dart`

The boot sequence is now:

1. `WidgetsFlutterBinding.ensureInitialized()` + load `Settings`
2. If mode D AND (vault exists OR legacy mode-D key exists) → run `UnlockScreen` first
3. Run `P1AuthMigration` (now able to read mode D legacy key with the unlocked passphrase)
4. Boot the home screen

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Refactor `main.dart`**

```dart
// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'data/migration/p1_auth_migration.dart';
import 'data/models/settings.dart';
import 'data/ssh/secure_key_storage_d.dart';
import 'data/ssh/ssh_key_registry_a.dart';
import 'data/ssh/ssh_key_registry_d.dart';
import 'data/storage/debug_log_service.dart';
import 'data/storage/json_storage_service.dart';
import 'presentation/providers/vault_passphrase_provider.dart';
import 'presentation/screens/server_list_screen.dart';
import 'presentation/screens/unlock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final dataDir = Directory('${dir.path}/lk_ssh_data');
  if (!await dataDir.exists()) await dataDir.create(recursive: true);

  final storage = JsonStorageService(dataDir);
  final settingsR = await storage.loadSettings();
  final settings = settingsR.unwrapOr(const Settings());
  if (settings.fileDebugMode) await DebugLogService.instance.setEnabled(true);

  final container = ProviderContainer();

  if (settings.keyStorageMode == KeyStorageMode.passphraseProtected) {
    // Mode D: gate the app behind UnlockScreen if there is anything to unlock.
    final vaultFile = File('${dataDir.path}/key_vault.bin');
    final hasVault = await vaultFile.exists();
    final hasLegacy = await SecureKeyStorageD().hasKey();
    if (hasVault || hasLegacy) {
      runApp(UncontrolledProviderScope(
        container: container,
        child: _UnlockGate(
          dataDir: dataDir,
          hasVault: hasVault,
          hasLegacy: hasLegacy,
          onUnlocked: (passphrase) async {
            container.read(vaultPassphraseProvider.notifier).unlock(passphrase);
            await _runMigration(container, dataDir, isModeD: true);
          },
        ),
      ));
      return;
    }
  }

  // Mode A (or mode D with nothing to unlock yet): run migration + go.
  await _runMigration(container, dataDir, isModeD: false);
  runApp(UncontrolledProviderScope(
    container: container,
    child: const LkSshApp(),
  ));
}

Future<void> _runMigration(
  ProviderContainer container,
  Directory dataDir, {
  required bool isModeD,
}) async {
  final storage = JsonStorageService(dataDir);
  final registry = isModeD
      ? SshKeyRegistryD(
          directory: dataDir,
          passphrase: container.read(vaultPassphraseProvider) ?? '',
        )
      : SshKeyRegistryA();
  final legacy = isModeD
      ? LegacyKeyReaderImpl.modeD(SecureKeyStorageD(),
          container.read(vaultPassphraseProvider) ?? '')
      : LegacyKeyReaderImpl(SecureKeyStorageA());
  await P1AuthMigration(
    storage: storage,
    registry: registry,
    legacy: legacy,
  ).run();
}

class _UnlockGate extends ConsumerStatefulWidget {
  const _UnlockGate({
    required this.dataDir,
    required this.hasVault,
    required this.hasLegacy,
    required this.onUnlocked,
  });

  final Directory dataDir;
  final bool hasVault;
  final bool hasLegacy;
  final Future<void> Function(String passphrase) onUnlocked;

  @override
  ConsumerState<_UnlockGate> createState() => _UnlockGateState();
}

class _UnlockGateState extends ConsumerState<_UnlockGate> {
  bool _unlocked = false;

  Future<bool> _verify(String passphrase) async {
    if (widget.hasVault) {
      final reg = SshKeyRegistryD(directory: widget.dataDir, passphrase: passphrase);
      // A successful loadVault on any keyId either returns Ok (with the key)
      // or KeyNotFound (vault decrypted, key missing) — both prove the passphrase.
      // KeyDecryptionError proves wrong passphrase.
      final probe = await reg.loadBytes('__probe__');
      switch (probe) {
        case Ok(): return true;
        case Err(:final error): return error is! KeyDecryptionError;
      }
    }
    if (widget.hasLegacy) {
      final r = await SecureKeyStorageD().loadKey(passphrase: passphrase);
      switch (r) {
        case Ok(): return true;
        case Err(:final error): return error is! KeyDecryptionError;
      }
    }
    // Neither vault nor legacy: any non-empty passphrase is "valid" (will be
    // used to seed a new vault on first key add). Caller should not invoke
    // _UnlockGate in this case — see main(). Treat as defensive.
    return passphrase.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return const LkSshApp();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _appTheme(),
      home: UnlockScreen(
        onSubmit: (passphrase) async {
          final ok = await _verify(passphrase);
          if (!ok) return false;
          await widget.onUnlocked(passphrase);
          if (mounted) setState(() => _unlocked = true);
          return true;
        },
      ),
    );
  }
}

ThemeData _appTheme() => ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0D0D),
        foregroundColor: Color(0xFF00FF41),
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF41),
        surface: Color(0xFF1A1A1A),
      ),
    );

class LkSshApp extends ConsumerWidget {
  const LkSshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LK-SSH',
      debugShowCheckedModeBanner: false,
      theme: _appTheme(),
      home: const ServerListScreen(),
    );
  }
}

extension<T> on Result<T, dynamic> {
  T unwrapOr(T fallback) => switch (this) {
    Ok(:final value) => value,
    Err() => fallback,
  };
}
```

> The `LegacyKeyReaderImpl.modeD(secureKeyStorageD, passphrase)` factory is added to `p1_auth_migration.dart` in this same task — see Step 2.

- [ ] **Step 2: Extend `LegacyKeyReaderImpl` to support mode D**

Add to `lib/data/migration/p1_auth_migration.dart`, replacing the existing `LegacyKeyReaderImpl`:

```dart
final class LegacyKeyReaderImpl implements LegacyKeyReader {
  LegacyKeyReaderImpl(this._storage) : _passphrase = null;
  LegacyKeyReaderImpl.modeD(this._storage, this._passphrase);

  final ISecureKeyStorage _storage;
  final String? _passphrase;

  @override
  Future<bool> hasKey() => _storage.hasKey();

  @override
  Future<Result<SecureKey, AppError>> loadKey() =>
      _storage.loadKey(passphrase: _passphrase);
}
```

(`SecureKeyStorageA.loadKey` ignores `passphrase`; `SecureKeyStorageD.loadKey` requires it. The conditional factory keeps both call sites trivial.)

- [ ] **Step 3: Run analyze + smoke**

Run: `flutter analyze --fatal-infos && flutter run`
Expected: clean. App boots; mode A users see no change. Mode D users see UnlockScreen if they had a v1 mode D key.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/data/migration/p1_auth_migration.dart
git commit -m "feat: bootstrap orchestrates UnlockScreen + migration for mode D"
```

---

### Task 4.1: `sshKeyRegistryProvider` + `sshKeysNotifierProvider`

**Files:**
- Create: `lib/presentation/providers/ssh_keys_provider.dart`

The notifier exposes the list of `SshKey` and CRUD that touches both `IStorageService.saveSshKeys` (metadata) and `ISshKeyRegistry.save` (bytes).

- [ ] **Step 1: Write the provider**

```dart
// lib/presentation/providers/ssh_keys_provider.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/settings.dart';
import '../../data/models/ssh_key.dart';
import '../../data/ssh/i_ssh_key_registry.dart';
import '../../data/ssh/ssh_key_registry_a.dart';
import '../../data/ssh/ssh_key_registry_d.dart';
import '../../data/storage/i_storage_service.dart';
import 'settings_provider.dart';
import 'storage_provider.dart';
import 'vault_passphrase_provider.dart';

part 'ssh_keys_provider.g.dart';

@riverpod
Future<ISshKeyRegistry> sshKeyRegistry(Ref ref) async {
  final settings = ref.watch(settingsNotifierProvider).valueOrNull;
  if (settings?.keyStorageMode == KeyStorageMode.passphraseProtected) {
    final pp = ref.watch(vaultPassphraseProvider);
    if (pp == null) {
      throw StateError(
          'Mode D registry requested before unlock — bootstrap should have gated.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${dir.path}/lk_ssh_data');
    return SshKeyRegistryD(directory: dataDir, passphrase: pp);
  }
  return SshKeyRegistryA();
}

@riverpod
class SshKeysNotifier extends _$SshKeysNotifier {
  static const _uuid = Uuid();

  @override
  Future<List<SshKey>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final r = await storage.loadSshKeys();
    return switch (r) {
      Ok(:final value) => value,
      Err() => <SshKey>[],
    };
  }

  Future<Result<SshKey, AppError>> add({
    required String label,
    required Uint8List bytes,
    String? passphrase,
  }) async {
    final id = _uuid.v4();
    final entry = SshKey(id: id, label: label, addedAt: DateTime.now());
    final registry = await ref.read(sshKeyRegistryProvider.future);
    final saveR = await registry.save(keyId: id, bytes: bytes, passphrase: passphrase);
    switch (saveR) {
      case Err(:final error): return Err(error);
      case Ok(): break;
    }
    final current = state.valueOrNull ?? const <SshKey>[];
    final next = [...current, entry];
    final storage = await ref.read(storageProvider.future);
    final saveMetaR = await storage.saveSshKeys(next);
    switch (saveMetaR) {
      case Err(:final error):
        await registry.delete(id);
        return Err(error);
      case Ok():
        state = AsyncData(next);
        return Ok(entry);
    }
  }

  Future<void> rename(String id, String newLabel) async {
    final current = state.valueOrNull ?? const <SshKey>[];
    final next = [
      for (final k in current) if (k.id == id) k.copyWith(label: newLabel) else k
    ];
    final storage = await ref.read(storageProvider.future);
    await storage.saveSshKeys(next);
    state = AsyncData(next);
  }

  Future<void> remove(String id) async {
    final registry = await ref.read(sshKeyRegistryProvider.future);
    await registry.delete(id);
    final current = state.valueOrNull ?? const <SshKey>[];
    final next = current.where((k) => k.id != id).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveSshKeys(next);
    state = AsyncData(next);
  }
}
```

- [ ] **Step 2: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 4: Smoke check**

Migration wiring is in Task 4.0c. This task only adds the notifier. `flutter run` should still launch the app unchanged.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/providers/ssh_keys_provider.dart lib/presentation/providers/ssh_keys_provider.g.dart
git commit -m "feat: sshKeysNotifierProvider"
```

---

### Task 4.2: `passwordStorageProvider` + `knownHostsStorageProvider`

**Files:**
- Create: `lib/presentation/providers/password_storage_provider.dart`
- Create: `lib/presentation/providers/known_hosts_provider.dart`

- [ ] **Step 1: Write `password_storage_provider.dart`**

```dart
// lib/presentation/providers/password_storage_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/storage/i_password_storage.dart';
import '../../data/storage/secure_password_storage.dart';

part 'password_storage_provider.g.dart';

@riverpod
IPasswordStorage passwordStorage(Ref ref) => SecurePasswordStorage();
```

- [ ] **Step 2: Write `known_hosts_provider.dart`**

```dart
// lib/presentation/providers/known_hosts_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/storage/i_known_hosts_storage.dart';
import '../../data/storage/json_known_hosts_storage.dart';

part 'known_hosts_provider.g.dart';

@riverpod
Future<IKnownHostsStorage> knownHostsStorage(Ref ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return JsonKnownHostsStorage(dir);
}
```

- [ ] **Step 3: Regenerate + analyze**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/providers/password_storage_provider.dart lib/presentation/providers/password_storage_provider.g.dart lib/presentation/providers/known_hosts_provider.dart lib/presentation/providers/known_hosts_provider.g.dart
git commit -m "feat: passwordStorageProvider + knownHostsStorageProvider"
```

---

### Task 4.3: Refactor `sshNotifier` to dispatch by `authMethod` and expose prompt stream

**Files:**
- Modify: `lib/presentation/providers/ssh_provider.dart`
- Test: extend with a mock-backed integration test (lightweight)

The new flow:

1. Read `Server.authMethod`.
2. Branch:
   - `key` → `SshKeyRegistry.loadBytes(server.keyId)` + `loadPassphrase(server.keyId)` → build `KeyCreds`.
   - `password` → if `savePassword` then load via `IPasswordStorage`; otherwise emit `PasswordPromptRequest` and await Completer.
   - `keyboardInteractive` → build `InteractiveCreds(onPrompt)` where `onPrompt` emits a `KbInteractivePromptRequest`.
3. Build `HostKeyVerifier` whose `onMismatch` emits `HostKeyMismatchRequest` and awaits Completer.
4. Call `SSHService.connectWith(...)`.

- [ ] **Step 1: Replace `ssh_provider.dart`**

```dart
// lib/presentation/providers/ssh_provider.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../../data/models/auth_credentials.dart';
import '../../data/models/auth_method.dart';
import '../../data/models/auth_prompt_request.dart';
import '../../data/models/server.dart';
import '../../data/models/session.dart';
import '../../domain/services/host_key_verifier.dart';
import '../../domain/services/ssh_service.dart';
import 'known_hosts_provider.dart';
import 'password_storage_provider.dart';
import 'sessions_provider.dart';
import 'ssh_keys_provider.dart';

part 'ssh_provider.g.dart';

@riverpod
class SshNotifier extends _$SshNotifier {
  SshConnection? _connection;
  final _prompts = StreamController<AuthPromptRequest>.broadcast();
  final _pending = <AuthPromptRequest>{};

  Stream<AuthPromptRequest> get prompts => _prompts.stream;

  @override
  AsyncValue<SshConnection?> build(String sessionId) {
    ref.onDispose(() {
      // Settle any prompt awaiting a UI response so the connect Future doesn't hang.
      for (final p in _pending) {
        switch (p) {
          case PasswordPromptRequest(:final completer):
            if (!completer.isCompleted) completer.complete(null);
          case KbInteractivePromptRequest(:final completer):
            if (!completer.isCompleted) completer.complete(null);
          case HostKeyMismatchRequest(:final completer):
            if (!completer.isCompleted) completer.complete(HostKeyDecision.reject);
        }
      }
      _pending.clear();
      _connection?.close();
      _prompts.close();
    });
    return const AsyncData(null);
  }

  void _emit(AuthPromptRequest req) {
    _pending.add(req);
    _prompts.add(req);
  }

  Future<Result<SshConnection, AppError>> connect(Server server) async {
    state = const AsyncLoading();

    final credsResult = await _resolveCredentials(server);
    final AuthCredentials credentials;
    switch (credsResult) {
      case Err(:final error):
        state = const AsyncData(null);
        ref
            .read(sessionsNotifierProvider.notifier)
            .updateStatus(sessionId, SessionStatus.error);
        return Err(error);
      case Ok(:final value):
        credentials = value;
    }

    final knownHosts = await ref.read(knownHostsStorageProvider.future);
    final verifier = HostKeyVerifier(
      storage: knownHosts,
      onMismatch: (change) async {
        final req = HostKeyMismatchRequest(change);
        _emit(req);
        final decision = await req.completer.future;
        _pending.remove(req);
        return decision;
      },
    );

    final svc = SSHService();
    final result = await svc.connectWith(
      server: server,
      credentials: credentials,
      verifier: verifier,
    );
    result.when(
      ok: (conn) {
        _connection = conn;
        state = AsyncData(conn);
        ref
            .read(sessionsNotifierProvider.notifier)
            .updateStatus(sessionId, SessionStatus.connected);
      },
      err: (_) {
        state = const AsyncData(null);
        ref
            .read(sessionsNotifierProvider.notifier)
            .updateStatus(sessionId, SessionStatus.error);
      },
    );
    return result;
  }

  Future<Result<AuthCredentials, AppError>> _resolveCredentials(Server server) async {
    switch (server.authMethod) {
      case AuthMethod.key:
        if (server.keyId == null) {
          return const Err(KeyNotFoundError());
        }
        final registry = await ref.read(sshKeyRegistryProvider.future);
        final bytesR = await registry.loadBytes(server.keyId!);
        switch (bytesR) {
          case Err(:final error):
            return Err(error);
          case Ok(:final value):
            final passphrase = await registry.loadPassphrase(server.keyId!);
            return Ok(KeyCreds(
              bytes: Uint8List.fromList(value.bytes),
              passphrase: passphrase,
            ));
        }
      case AuthMethod.password:
        String? password;
        if (server.savePassword) {
          password = await ref.read(passwordStorageProvider).load(server.id);
        }
        password ??= await _promptPassword(server);
        if (password == null) {
          return const Err(SshAuthError("Connexion annulée par l'utilisateur."));
        }
        return Ok(PasswordCreds(password));
      case AuthMethod.keyboardInteractive:
        return Ok(InteractiveCreds((req) async {
          final pr = KbInteractivePromptRequest(req);
          _emit(pr);
          final answers = await pr.completer.future;
          _pending.remove(pr);
          return answers;
        }));
    }
  }

  Future<String?> _promptPassword(Server server) async {
    final pr = PasswordPromptRequest(user: server.username, host: server.host);
    _emit(pr);
    final pp = await pr.completer.future;
    _pending.remove(pr);
    return pp;
  }

  void disconnect() {
    _connection?.close();
    _connection = null;
    state = const AsyncData(null);
    ref
        .read(sessionsNotifierProvider.notifier)
        .updateStatus(sessionId, SessionStatus.disconnected);
  }
}
```

- [ ] **Step 2: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Update callers**

Search for `ref.read(sshNotifierProvider(...).notifier).connect(server, key)` (the old 2-arg signature) and update to `connect(server)` (the credentials are resolved internally now).

Run: `grep -rn "sshNotifierProvider.*notifier.*connect" lib/`
Expected: 1-2 call sites in `terminal_screen.dart` (and possibly a wrapper). Update each.

- [ ] **Step 4: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean. If a previously-passed `SecureKey` is now unused in `terminal_screen`, remove the dead code.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/providers/ssh_provider.dart lib/presentation/providers/ssh_provider.g.dart lib/presentation/screens/terminal_screen.dart
git commit -m "feat: sshNotifier dispatches by authMethod, exposes prompt stream"
```

---

## Step 5 — UI: keys screen + server form

### Task 5.1: `KeyEditorSheet` widget

**Files:**
- Create: `lib/presentation/widgets/key_editor_sheet.dart`

A `showModalBottomSheet`-friendly widget that returns a `({String label, Uint8List bytes, String? passphrase})` record on submit, or null on cancel. It includes a "Tester" button that calls `SSHKeyPair.fromPem(...)` and surfaces any parse error inline.

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/key_editor_sheet.dart
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

typedef KeyEditorResult = ({String label, Uint8List bytes, String? passphrase});

class KeyEditorSheet extends StatefulWidget {
  const KeyEditorSheet({super.key});

  static Future<KeyEditorResult?> show(BuildContext context) {
    return showModalBottomSheet<KeyEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const KeyEditorSheet(),
      ),
    );
  }

  @override
  State<KeyEditorSheet> createState() => _KeyEditorSheetState();
}

class _KeyEditorSheetState extends State<KeyEditorSheet> {
  final _label = TextEditingController();
  final _pem = TextEditingController();
  final _pp = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _pem.dispose();
    _pp.dispose();
    super.dispose();
  }

  bool _tryParse() {
    try {
      SSHKeyPair.fromPem(_pem.text, _pp.text.isEmpty ? null : _pp.text);
      setState(() => _error = null);
      return true;
    } catch (e) {
      setState(() => _error = 'Clé invalide ou mauvaise passphrase.');
      return false;
    }
  }

  void _submit() {
    if (_label.text.trim().isEmpty) {
      setState(() => _error = 'Le label est requis.');
      return;
    }
    if (!_tryParse()) return;
    Navigator.pop<KeyEditorResult>(context, (
      label: _label.text.trim(),
      bytes: Uint8List.fromList(_pem.text.codeUnits),
      passphrase: _pp.text.isEmpty ? null : _pp.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouvelle clé SSH', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'MacBook perso',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pem,
            maxLines: 8,
            minLines: 4,
            decoration: const InputDecoration(
              labelText: 'Clé privée (PEM)',
              hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pp,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Passphrase (si chiffrée)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop<KeyEditorResult>(context, null),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _tryParse,
                child: const Text('Tester'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/key_editor_sheet.dart
git commit -m "feat: KeyEditorSheet widget for adding SSH keys"
```

---

### Task 5.2: `keys_screen`

**Files:**
- Create: `lib/presentation/screens/keys_screen.dart`

- [ ] **Step 1: Write the screen**

```dart
// lib/presentation/screens/keys_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../data/models/ssh_key.dart';
import '../providers/servers_provider.dart';
import '../providers/ssh_keys_provider.dart';
import '../widgets/key_editor_sheet.dart';

class KeysScreen extends ConsumerWidget {
  const KeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(sshKeysNotifierProvider);
    final servers = ref.watch(serversNotifierProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Clés SSH')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await KeyEditorSheet.show(context);
          if (result == null) return;
          await ref.read(sshKeysNotifierProvider.notifier).add(
                label: result.label,
                bytes: result.bytes,
                passphrase: result.passphrase,
              );
        },
        child: const Icon(Icons.add),
      ),
      body: keysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (keys) {
          if (keys.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune clé enregistrée.\nAppuyez sur + pour en ajouter une.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: keys.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final k = keys[i];
              final usedBy = servers.where((s) => s.keyId == k.id).length;
              return ListTile(
                title: Text(k.label),
                subtitle: Text(
                  'Ajoutée le ${k.addedAt.toLocal().toString().split('.').first} · '
                  'utilisée par $usedBy serveur${usedBy > 1 ? 's' : ''}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'rename') {
                      await _rename(context, ref, k);
                    } else if (v == 'delete') {
                      await _confirmAndDelete(context, ref, k, usedBy);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renommer')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, SshKey k) async {
    final ctrl = TextEditingController(text: k.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renommer la clé'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('OK')),
        ],
      ),
    );
    if (newLabel != null && newLabel.trim().isNotEmpty) {
      await ref.read(sshKeysNotifierProvider.notifier).rename(k.id, newLabel.trim());
    }
  }

  Future<void> _confirmAndDelete(
      BuildContext context, WidgetRef ref, SshKey k, int usedBy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la clé ?'),
        content: Text(
          usedBy == 0
              ? 'Cette clé n\'est utilisée par aucun serveur.'
              : 'Cette clé est utilisée par $usedBy serveur${usedBy > 1 ? 's' : ''}. '
                'Ces serveurs ne pourront plus se connecter sans réassignation.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sshKeysNotifierProvider.notifier).remove(k.id);
    }
  }
}
```

- [ ] **Step 2: Add entry in `settings_screen`**

In `lib/presentation/screens/settings_screen.dart`, add a `ListTile` (under the keystore mode section) that pushes `KeysScreen`:

```dart
ListTile(
  leading: const Icon(Icons.key),
  title: const Text('Clés SSH'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const KeysScreen())),
),
```

Add the import.

- [ ] **Step 3: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/keys_screen.dart lib/presentation/screens/settings_screen.dart
git commit -m "feat: KeysScreen + settings entry"
```

---

### Task 5.3: Auth section in `server_form_screen`

**Files:**
- Modify: `lib/presentation/screens/server_form_screen.dart`
- Modify: `lib/presentation/providers/servers_provider.dart` (extend `newServer(...)` if needed)

- [ ] **Step 1: Add the auth section**

Replace the relevant parts of `server_form_screen.dart`. The form now tracks `_authMethod`, `_keyId`, `_passwordCtrl`, `_savePassword`. Validation at submit:

- if `key` and `keyId == null` → show snackbar error and return
- if `password` and `_passwordCtrl.text.isEmpty` → show snackbar error

```dart
// Inside _ServerFormScreenState, add fields:
late AuthMethod _authMethod;
String? _keyId;
late final TextEditingController _passwordCtrl;
late bool _savePassword;

@override
void initState() {
  super.initState();
  _labelCtrl = TextEditingController(text: widget.server?.label ?? '');
  _hostCtrl = TextEditingController(text: widget.server?.host ?? '');
  _portCtrl = TextEditingController(text: '${widget.server?.port ?? 22}');
  _userCtrl = TextEditingController(text: widget.server?.username ?? '');
  _authMethod = widget.server?.authMethod ?? AuthMethod.key;
  _keyId = widget.server?.keyId;
  _passwordCtrl = TextEditingController();
  _savePassword = widget.server?.savePassword ?? false;
}
```

In `build`, after the user field, before the submit button, insert:

```dart
const SizedBox(height: 24),
const Text('Authentification', style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
DropdownButtonFormField<AuthMethod>(
  value: _authMethod,
  decoration: const InputDecoration(
    labelText: 'Méthode',
    border: OutlineInputBorder(),
  ),
  items: const [
    DropdownMenuItem(value: AuthMethod.key, child: Text('Clé SSH')),
    DropdownMenuItem(value: AuthMethod.password, child: Text('Mot de passe')),
    DropdownMenuItem(value: AuthMethod.keyboardInteractive, child: Text('Keyboard-interactive')),
  ],
  onChanged: (v) => setState(() => _authMethod = v ?? AuthMethod.key),
),
const SizedBox(height: 12),
if (_authMethod == AuthMethod.key) _buildKeyPicker(),
if (_authMethod == AuthMethod.password) _buildPasswordFields(),
if (_authMethod == AuthMethod.keyboardInteractive)
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'Les questions du serveur s\'afficheront à la connexion.',
      style: TextStyle(fontStyle: FontStyle.italic),
    ),
  ),
```

Helpers in the State class:

```dart
Widget _buildKeyPicker() {
  final keysAsync = ref.watch(sshKeysNotifierProvider);
  return keysAsync.when(
    loading: () => const LinearProgressIndicator(),
    error: (e, _) => Text('Erreur: $e'),
    data: (keys) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: keys.any((k) => k.id == _keyId) ? _keyId : null,
          decoration: const InputDecoration(
            labelText: 'Clé',
            border: OutlineInputBorder(),
          ),
          hint: Text(keys.isEmpty
              ? 'Aucune clé enregistrée — ajoutez-en une'
              : 'Choisir une clé'),
          items: [
            for (final k in keys)
              DropdownMenuItem(value: k.id, child: Text(k.label)),
          ],
          onChanged: keys.isEmpty
              ? null
              : (v) => setState(() => _keyId = v),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle clé'),
          onPressed: () async {
            final result = await KeyEditorSheet.show(context);
            if (result == null) return;
            final added = await ref
                .read(sshKeysNotifierProvider.notifier)
                .add(
                  label: result.label,
                  bytes: result.bytes,
                  passphrase: result.passphrase,
                );
            switch (added) {
              case Ok(:final value):
                setState(() => _keyId = value.id);
              case Err():
                break;
            }
          },
        ),
      ],
    ),
  );
}

Widget _buildPasswordFields() {
  return Column(
    children: [
      TextField(
        controller: _passwordCtrl,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Mot de passe',
          border: OutlineInputBorder(),
        ),
      ),
      ValueListenableBuilder(
        valueListenable: _passwordCtrl,
        builder: (_, value, __) => value.text.isEmpty
            ? const SizedBox.shrink()
            : CheckboxListTile(
                value: _savePassword,
                onChanged: (v) => setState(() => _savePassword = v ?? false),
                title: const Text('Se souvenir'),
                contentPadding: EdgeInsets.zero,
              ),
      ),
    ],
  );
}
```

Add imports:

```dart
import '../../core/result.dart';
import '../../data/models/auth_method.dart';
import '../../data/models/ssh_key.dart';
import '../providers/ssh_keys_provider.dart';
import '../providers/password_storage_provider.dart';
import '../widgets/key_editor_sheet.dart';
```

- [ ] **Step 2: Update `_submit` to enforce auth validation and persist password**

```dart
void _submit() async {
  if (!_formKey.currentState!.validate()) return;
  if (_authMethod == AuthMethod.key && _keyId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sélectionnez une clé.')),
    );
    return;
  }
  if (_authMethod == AuthMethod.password && _passwordCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe requis.')),
    );
    return;
  }

  final notifier = ref.read(serversNotifierProvider.notifier);
  final pwdStorage = ref.read(passwordStorageProvider);

  final isNew = widget.server == null;
  final base = isNew
      ? newServer(
          label: _labelCtrl.text.trim(),
          host: _hostCtrl.text.trim(),
          port: int.parse(_portCtrl.text.trim()),
          username: _userCtrl.text.trim(),
        )
      : widget.server!;

  final updated = base.copyWith(
    label: _labelCtrl.text.trim(),
    host: _hostCtrl.text.trim(),
    port: int.parse(_portCtrl.text.trim()),
    username: _userCtrl.text.trim(),
    authMethod: _authMethod,
    keyId: _authMethod == AuthMethod.key ? _keyId : null,
    savePassword: _authMethod == AuthMethod.password ? _savePassword : false,
  );

  if (isNew) {
    notifier.add(updated);
  } else {
    notifier.replace(updated);
  }

  if (_authMethod == AuthMethod.password) {
    if (_savePassword) {
      await pwdStorage.save(updated.id, _passwordCtrl.text);
    } else {
      await pwdStorage.delete(updated.id);
    }
  } else {
    await pwdStorage.delete(updated.id);
  }

  if (mounted) Navigator.pop(context);
}
```

The widget now needs to be `ConsumerStatefulWidget` if it isn't already (it is — it already uses `ref`). No structural change.

- [ ] **Step 3: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 4: Smoke test on device or emulator**

Run: `flutter run`
- Add a new server, choose `key`, ensure dropdown shows the migrated `Clé par défaut`. Save → verify it persists.
- Edit it, change to `password`, type a password, check "Se souvenir". Save → verify password stored (re-opening shows nothing in the field; that's expected — we don't pre-fill saved passwords).
- Switch to `keyboardInteractive`. Save.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/server_form_screen.dart
git commit -m "feat: auth method section in server form (key/password/KI)"
```

---

## Step 6 — UI: connection prompts

### Task 6.1: `PasswordPromptSheet`

**Files:**
- Create: `lib/presentation/widgets/password_prompt_sheet.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/password_prompt_sheet.dart
import 'package:flutter/material.dart';

class PasswordPromptSheet extends StatefulWidget {
  const PasswordPromptSheet({super.key, required this.user, required this.host});
  final String user;
  final String host;

  static Future<String?> show(BuildContext context, {required String user, required String host}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PasswordPromptSheet(user: user, host: host),
      ),
    );
  }

  @override
  State<PasswordPromptSheet> createState() => _PasswordPromptSheetState();
}

class _PasswordPromptSheetState extends State<PasswordPromptSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mot de passe pour ${widget.user}@${widget.host}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => Navigator.pop(context, _ctrl.text),
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _ctrl.text),
                child: const Text('Connecter'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze + commit**

Run: `flutter analyze --fatal-infos`

```bash
git add lib/presentation/widgets/password_prompt_sheet.dart
git commit -m "feat: PasswordPromptSheet"
```

---

### Task 6.2: `KeyboardInteractiveSheet`

**Files:**
- Create: `lib/presentation/widgets/keyboard_interactive_sheet.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/keyboard_interactive_sheet.dart
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

class KeyboardInteractiveSheet extends StatefulWidget {
  const KeyboardInteractiveSheet({super.key, required this.request});
  final SSHUserInfoRequest request;

  static Future<List<String>?> show(BuildContext context, SSHUserInfoRequest req) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: KeyboardInteractiveSheet(request: req),
      ),
    );
  }

  @override
  State<KeyboardInteractiveSheet> createState() => _KeyboardInteractiveSheetState();
}

class _KeyboardInteractiveSheetState extends State<KeyboardInteractiveSheet> {
  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      widget.request.prompts.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.request.name.isNotEmpty)
            Text(widget.request.name,
                style: Theme.of(context).textTheme.titleMedium),
          if (widget.request.instruction.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.request.instruction),
          ],
          const SizedBox(height: 12),
          for (int i = 0; i < widget.request.prompts.length; i++) ...[
            TextField(
              controller: _ctrls[i],
              obscureText: !widget.request.prompts[i].echo,
              autofocus: i == 0,
              decoration: InputDecoration(
                labelText: widget.request.prompts[i].prompt,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                    context, _ctrls.map((c) => c.text).toList()),
                child: const Text('Soumettre'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze + commit**

```bash
flutter analyze --fatal-infos
git add lib/presentation/widgets/keyboard_interactive_sheet.dart
git commit -m "feat: KeyboardInteractiveSheet"
```

---

### Task 6.3: `HostKeyMismatchSheet`

**Files:**
- Create: `lib/presentation/widgets/host_key_mismatch_sheet.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/host_key_mismatch_sheet.dart
import 'package:flutter/material.dart';

import '../../data/models/auth_prompt_request.dart';

class HostKeyMismatchSheet extends StatefulWidget {
  const HostKeyMismatchSheet({super.key, required this.change});
  final HostKeyChange change;

  static Future<HostKeyDecision> show(BuildContext context, HostKeyChange change) {
    return showModalBottomSheet<HostKeyDecision>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => HostKeyMismatchSheet(change: change),
    ).then((v) => v ?? HostKeyDecision.reject);
  }

  @override
  State<HostKeyMismatchSheet> createState() => _HostKeyMismatchSheetState();
}

class _HostKeyMismatchSheetState extends State<HostKeyMismatchSheet> {
  bool _detailsOpen = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.change;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Empreinte du serveur changée !',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${c.host}:${c.port}\n\n'
            'L\'empreinte SHA256 du serveur a changé depuis la dernière connexion. '
            'Cela peut indiquer un changement légitime du serveur (réinstallation, '
            'rotation de clé) ou une attaque MitM.',
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _detailsOpen = !_detailsOpen),
            child: Text(_detailsOpen ? 'Masquer les détails' : 'Voir les détails'),
          ),
          if (_detailsOpen) ...[
            const SizedBox(height: 4),
            _Fp(label: 'Ancienne', value: c.oldFingerprint),
            const SizedBox(height: 8),
            _Fp(label: 'Nouvelle', value: c.newFingerprint),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, HostKeyDecision.reject),
            child: const Text('Annuler la connexion'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () =>
                Navigator.pop(context, HostKeyDecision.acceptAndPin),
            child: const Text('Faire confiance à la nouvelle empreinte'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Fp extends StatelessWidget {
  const _Fp({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SelectableText(
          'SHA256:$value',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze + commit**

```bash
flutter analyze --fatal-infos
git add lib/presentation/widgets/host_key_mismatch_sheet.dart
git commit -m "feat: HostKeyMismatchSheet"
```

---

### Task 6.4: Wire prompt stream in `terminal_screen`

**Files:**
- Modify: `lib/presentation/screens/terminal_screen.dart`

- [ ] **Step 1: Add the stream subscription**

Subscribe to `notifier.prompts` from inside `initState` — directly, no post-frame. `ref` is stable in a `ConsumerStatefulWidget`. Subscriptions during build can race with the build cycle, and post-frame callbacks may fire after dispose.

```dart
// Add fields to the State class:
StreamSubscription<AuthPromptRequest>? _promptSub;

@override
void initState() {
  super.initState();
  final notifier = ref.read(sshNotifierProvider(widget.sessionId).notifier);
  _promptSub = notifier.prompts.listen(_handlePrompt);
}

@override
void dispose() {
  _promptSub?.cancel();
  super.dispose();
}

Future<void> _handlePrompt(AuthPromptRequest req) async {
  if (!mounted) return;
  switch (req) {
    case PasswordPromptRequest():
      final pwd = await PasswordPromptSheet.show(
        context,
        user: req.user,
        host: req.host,
      );
      if (!req.completer.isCompleted) req.completer.complete(pwd);
    case KbInteractivePromptRequest():
      final answers =
          await KeyboardInteractiveSheet.show(context, req.request);
      if (!req.completer.isCompleted) req.completer.complete(answers);
    case HostKeyMismatchRequest():
      final decision =
          await HostKeyMismatchSheet.show(context, req.change);
      if (!req.completer.isCompleted) req.completer.complete(decision);
  }
}
```

Add the imports:

```dart
import 'dart:async';
import '../../data/models/auth_prompt_request.dart';
import '../widgets/password_prompt_sheet.dart';
import '../widgets/keyboard_interactive_sheet.dart';
import '../widgets/host_key_mismatch_sheet.dart';
```

> Edge case: if the user navigates away while a prompt is pending, the Completer may resolve to null/reject; the connection then fails gracefully via `SshAuthError('Connexion annulée par l\'utilisateur.')`. The notifier `dispose` already closes the StreamController, which terminates pending listeners safely.

- [ ] **Step 2: Analyze**

Run: `flutter analyze --fatal-infos`
Expected: clean.

- [ ] **Step 3: Manual smoke test on device — gating release**

Run: `flutter run`. Cover the four scenarios from the spec:

1. **Server v1 (key auth)** — connect to a server you used in v1. Should connect without any prompt (uses migrated `default` key).
2. **Server with password auth** — create a server with `authMethod=password`, no save. Connect → password sheet appears, enter, connect.
3. **Server with password auth + remember** — same as above, save the password. Disconnect, reconnect → no prompt (loads from `IPasswordStorage`).
4. **Keyboard-interactive** — if you have access to a server with `ChallengeResponseAuthentication yes` (e.g. a 2FA server), test that prompts render correctly.
5. **Fingerprint mismatch** — connect to a server (auto-pins). Now manually edit `<app docs dir>/known_hosts.json` and change the fingerprint, then reconnect → mismatch sheet appears with old/new fingerprints; "Annuler" aborts; "Accepter" updates the stored fingerprint.
6. **Mode D end-to-end** — install P1 over a v1 build using mode D.
   a. App boots → `UnlockScreen` appears. Type wrong passphrase → red error, re-prompt. Type correct passphrase → migration runs (legacy bytes are decrypted, written to `SshKeyRegistryD` vault, the legacy mode-D key entry is left intact for safety; `SshKey "default"` metadata created; servers retagged).
   b. Connect to a server using the migrated `default` key → no extra prompt (vault is unlocked for the session).
   c. Open the keys screen → FAB works; tap "+", import a second key → it lands in the vault encrypted with the same passphrase.
   d. Restart the app → `UnlockScreen` appears again (passphrase is in memory, not persisted). Unlock → both keys still load.
   e. Verify on disk: `key_vault.bin` exists in the docs dir, is opaque binary, and the legacy mode D entries (`ssh_key_enc_d` / `ssh_key_salt_d` in encrypted shared prefs) are still present (cleanup of legacy storage is deferred to P2).

If any of these fails, fix before merging.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/terminal_screen.dart
git commit -m "feat: terminal_screen handles password/KI/host-key-mismatch prompts"
```

---

### Task 6.5: Update `docs/TECHNICAL.md`

**Files:**
- Modify: `docs/TECHNICAL.md`

- [ ] **Step 1: Add a "Phase 1 — Auth & host trust" section**

Add a new section to `docs/TECHNICAL.md` documenting:
- The three auth methods and how `Server.authMethod` drives the dispatch
- The `HostKeyVerifier` TOFU flow (auto-pin, mismatch decisions)
- The multi-key registry (mode A active, mode D currently TODO P2)
- The migration `migrationP1Done` flag and the `servers.json.pre-p1` backup path
- Locations of the new prompt sheets and their Completer pattern

Reference the spec at `docs/superpowers/specs/2026-04-27-auth-host-trust-design.md`.

- [ ] **Step 2: Commit**

```bash
git add docs/TECHNICAL.md
git commit -m "docs: document Phase 1 auth & host trust in TECHNICAL.md"
```

---

## Final verification

- [ ] **All tests pass**

Run: `flutter test`
Expected: every test from `test/` passes (existing v1 tests + new ones).

- [ ] **Analyze clean**

Run: `flutter analyze --fatal-infos`
Expected: `No issues found!`

- [ ] **Manual gate on device**

Run the 5 scenarios from Task 6.4 step 3. All pass.

- [ ] **Branch is mergeable**

Run: `git log --oneline main..HEAD | wc -l`
Expected: ~25 commits, each conventional and atomic. No work-in-progress squash-fodder.

- [ ] **Open PR**

Suggested title: `feat: Phase 1 — auth multi-méthodes + host trust + multi-keys`

Body bullets: link to spec, list of features added (key/password/KI auth, TOFU, multi-keys, migration), known limitations (mode D for multi-keys deferred to P2 — see TODO in `ssh_keys_provider.dart`).
