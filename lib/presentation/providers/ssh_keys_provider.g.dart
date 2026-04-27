// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_keys_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sshKeyRegistryHash() => r'744a35468ea37aceafc1312c792cfa74cb0cf9f5';

/// See also [sshKeyRegistry].
@ProviderFor(sshKeyRegistry)
final sshKeyRegistryProvider =
    AutoDisposeFutureProvider<ISshKeyRegistry>.internal(
  sshKeyRegistry,
  name: r'sshKeyRegistryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sshKeyRegistryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SshKeyRegistryRef = AutoDisposeFutureProviderRef<ISshKeyRegistry>;
String _$sshKeysNotifierHash() => r'9b484073fa8e21ea1457c152a86b61b2cc17dc66';

/// See also [SshKeysNotifier].
@ProviderFor(SshKeysNotifier)
final sshKeysNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SshKeysNotifier, List<SshKey>>.internal(
  SshKeysNotifier.new,
  name: r'sshKeysNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sshKeysNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SshKeysNotifier = AutoDisposeAsyncNotifier<List<SshKey>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
