// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$terminalHash() => r'00ef27e2e4328fe6d309f795b72bcc7d968c617a';

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

/// See also [terminal].
@ProviderFor(terminal)
const terminalProvider = TerminalFamily();

/// See also [terminal].
class TerminalFamily extends Family<Terminal> {
  /// See also [terminal].
  const TerminalFamily();

  /// See also [terminal].
  TerminalProvider call(
    String sessionId,
  ) {
    return TerminalProvider(
      sessionId,
    );
  }

  @override
  TerminalProvider getProviderOverride(
    covariant TerminalProvider provider,
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
  String? get name => r'terminalProvider';
}

/// See also [terminal].
class TerminalProvider extends AutoDisposeProvider<Terminal> {
  /// See also [terminal].
  TerminalProvider(
    String sessionId,
  ) : this._internal(
          (ref) => terminal(
            ref as TerminalRef,
            sessionId,
          ),
          from: terminalProvider,
          name: r'terminalProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$terminalHash,
          dependencies: TerminalFamily._dependencies,
          allTransitiveDependencies: TerminalFamily._allTransitiveDependencies,
          sessionId: sessionId,
        );

  TerminalProvider._internal(
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
  Override overrideWith(
    Terminal Function(TerminalRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TerminalProvider._internal(
        (ref) => create(ref as TerminalRef),
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
  AutoDisposeProviderElement<Terminal> createElement() {
    return _TerminalProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalProvider && other.sessionId == sessionId;
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
mixin TerminalRef on AutoDisposeProviderRef<Terminal> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _TerminalProviderElement extends AutoDisposeProviderElement<Terminal>
    with TerminalRef {
  _TerminalProviderElement(super.provider);

  @override
  String get sessionId => (origin as TerminalProvider).sessionId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
