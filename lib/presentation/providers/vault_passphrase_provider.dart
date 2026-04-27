import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_passphrase_provider.g.dart';

@Riverpod(keepAlive: true)
class VaultPassphrase extends _$VaultPassphrase {
  @override
  String? build() => null;

  void unlock(String passphrase) => state = passphrase;
  void lock() => state = null;
}
