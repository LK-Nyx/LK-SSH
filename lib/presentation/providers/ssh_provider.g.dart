// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sshNotifierHash() => r'312fb847571af2438a8e0fd074f2bd0a3ac9f968';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$SshNotifier
    extends BuildlessAutoDisposeNotifier<AsyncValue<SshConnection?>> {
  late final String sessionId;

  AsyncValue<SshConnection?> build(
    String sessionId,
  );
}

/// See also [SshNotifier].
@ProviderFor(SshNotifier)
const sshNotifierProvider = SshNotifierFamily();

/// See also [SshNotifier].
class SshNotifierFamily extends Family<AsyncValue<SshConnection?>> {
  /// See also [SshNotifier].
  const SshNotifierFamily();

  /// See also [SshNotifier].
  SshNotifierProvider call(
    String sessionId,
  ) {
    return SshNotifierProvider(
      sessionId,
    );
  }

  @override
  SshNotifierProvider getProviderOverride(
    covariant SshNotifierProvider provider,
  ) {
    return call(
      provider.sessionId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sshNotifierProvider';
}

/// See also [SshNotifier].
class SshNotifierProvider extends AutoDisposeNotifierProviderImpl<SshNotifier,
    AsyncValue<SshConnection?>> {
  /// See also [SshNotifier].
  SshNotifierProvider(
    String sessionId,
  ) : this._internal(
          () => SshNotifier()..sessionId = sessionId,
          from: sshNotifierProvider,
          name: r'sshNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sshNotifierHash,
          dependencies: SshNotifierFamily._dependencies,
          allTransitiveDependencies:
              SshNotifierFamily._allTransitiveDependencies,
          sessionId: sessionId,
        );

  SshNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String sessionId;

  @override
  AsyncValue<SshConnection?> runNotifierBuild(
    covariant SshNotifier notifier,
  ) {
    return notifier.build(
      sessionId,
    );
  }

  @override
  Override overrideWith(SshNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SshNotifierProvider._internal(
        () => create()..sessionId = sessionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<SshNotifier, AsyncValue<SshConnection?>>
      createElement() {
    return _SshNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SshNotifierProvider && other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SshNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<SshConnection?>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _SshNotifierProviderElement extends AutoDisposeNotifierProviderElement<
    SshNotifier, AsyncValue<SshConnection?>> with SshNotifierRef {
  _SshNotifierProviderElement(super.provider);

  @override
  String get sessionId => (origin as SshNotifierProvider).sessionId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
