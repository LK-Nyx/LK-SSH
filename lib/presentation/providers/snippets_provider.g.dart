// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snippets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$snippetsNotifierHash() => r'f20bb4e2a4bf1d16b98013b20e69f3aadb4bd240';

/// See also [SnippetsNotifier].
@ProviderFor(SnippetsNotifier)
final snippetsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SnippetsNotifier, List<Snippet>>.internal(
  SnippetsNotifier.new,
  name: r'snippetsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$snippetsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SnippetsNotifier = AutoDisposeAsyncNotifier<List<Snippet>>;
String _$categoriesNotifierHash() =>
    r'a9a15f25fc446493da501e80e98c0e7acc3aa854';

/// See also [CategoriesNotifier].
@ProviderFor(CategoriesNotifier)
final categoriesNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CategoriesNotifier, List<Category>>.internal(
  CategoriesNotifier.new,
  name: r'categoriesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoriesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CategoriesNotifier = AutoDisposeAsyncNotifier<List<Category>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
