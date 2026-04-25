import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/settings.dart';
import '../../data/ssh/i_secure_key_storage.dart';
import '../../data/ssh/secure_key_storage_a.dart';
import '../../data/ssh/secure_key_storage_d.dart';
import 'settings_provider.dart';

part 'secure_key_provider.g.dart';

@riverpod
ISecureKeyStorage secureKeyStorage(Ref ref) {
  final settings = ref.watch(settingsNotifierProvider).valueOrNull;
  return switch (settings?.keyStorageMode) {
    KeyStorageMode.passphraseProtected => SecureKeyStorageD(),
    _ => SecureKeyStorageA(),
  };
}
