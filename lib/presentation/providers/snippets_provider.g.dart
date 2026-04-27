// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snippets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$snippetsNotifierHash() => r'f2f9c4c78ce373ec3272cd253d196fb74ddfe3b1';

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
    r'31b5a5832b871843936ae4cf62460f9dbff7c1ff';

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
