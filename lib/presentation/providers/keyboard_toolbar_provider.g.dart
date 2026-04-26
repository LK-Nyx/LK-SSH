// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyboard_toolbar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$keyboardToolbarHash() => r'4edb0523cdc5fbdbf831f25f03cce07d0dbab91c';

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

abstract class _$KeyboardToolbar
    extends BuildlessAutoDisposeNotifier<KeyboardToolbarState> {
  late final String sessionId;

  KeyboardToolbarState build(
    String sessionId,
  );
}

/// See also [KeyboardToolbar].
@ProviderFor(KeyboardToolbar)
const keyboardToolbarProvider = KeyboardToolbarFamily();

/// See also [KeyboardToolbar].
class KeyboardToolbarFamily extends Family<KeyboardToolbarState> {
  /// See also [KeyboardToolbar].
  const KeyboardToolbarFamily();

  /// See also [KeyboardToolbar].
  KeyboardToolbarProvider call(
    String sessionId,
  ) {
    return KeyboardToolbarProvider(
      sessionId,
    );
  }

  @override
  KeyboardToolbarProvider getProviderOverride(
    covariant KeyboardToolbarProvider provider,
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
  String? get name => r'keyboardToolbarProvider';
}

/// See also [KeyboardToolbar].
class KeyboardToolbarProvider extends AutoDisposeNotifierProviderImpl<
    KeyboardToolbar, KeyboardToolbarState> {
  /// See also [KeyboardToolbar].
  KeyboardToolbarProvider(
    String sessionId,
  ) : this._internal(
          () => KeyboardToolbar()..sessionId = sessionId,
          from: keyboardToolbarProvider,
          name: r'keyboardToolbarProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$keyboardToolbarHash,
          dependencies: KeyboardToolbarFamily._dependencies,
          allTransitiveDependencies:
              KeyboardToolbarFamily._allTransitiveDependencies,
          sessionId: sessionId,
        );

  KeyboardToolbarProvider._internal(
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
  KeyboardToolbarState runNotifierBuild(
    covariant KeyboardToolbar notifier,
  ) {
    return notifier.build(
      sessionId,
    );
  }

  @override
  Override overrideWith(KeyboardToolbar Function() create) {
    return ProviderOverride(
      origin: this,
      override: KeyboardToolbarProvider._internal(
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
  AutoDisposeNotifierProviderElement<KeyboardToolbar, KeyboardToolbarState>
      createElement() {
    return _KeyboardToolbarProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is KeyboardToolbarProvider && other.sessionId == sessionId;
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
mixin KeyboardToolbarRef
    on AutoDisposeNotifierProviderRef<KeyboardToolbarState> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _KeyboardToolbarProviderElement
    extends AutoDisposeNotifierProviderElement<KeyboardToolbar,
        KeyboardToolbarState> with KeyboardToolbarRef {
  _KeyboardToolbarProviderElement(super.provider);

  @override
  String get sessionId => (origin as KeyboardToolbarProvider).sessionId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
