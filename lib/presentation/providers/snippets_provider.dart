import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/category.dart';
import '../../data/models/snippet.dart';
import 'storage_provider.dart';

part 'snippets_provider.g.dart';

@riverpod
class SnippetsNotifier extends _$SnippetsNotifier {
  @override
  Future<List<Snippet>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final result = await storage.loadSnippets();
    return result.when(ok: (s) => s, err: (_) => []);
  }

  Future<void> add(Snippet snippet) async {
    final current = await future;
    final updated = [...current, snippet];
    final storage = await ref.read(storageProvider.future);
    await storage.saveSnippets(updated);
    state = AsyncData(updated);
  }

  Future<void> replace(Snippet snippet) async {
    final current = await future;
    final updated =
        current.map((s) => s.id == snippet.id ? snippet : s).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveSnippets(updated);
    state = AsyncData(updated);
  }

  Future<void> delete(String id) async {
    final current = await future;
    final updated = current.where((s) => s.id != id).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveSnippets(updated);
    state = AsyncData(updated);
  }
}

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  static final _defaults = [
    const Category(id: 'system', label: 'System'),
    const Category(id: 'docker', label: 'Docker'),
    const Category(id: 'git', label: 'Git'),
  ];

  @override
  Future<List<Category>> build() async {
    final storage = await ref.watch(storageProvider.future);
    final result = await storage.loadCategories();
    if (result.isErr) return _defaults;
    final cats = result.value;
    return cats.isEmpty ? _defaults : cats;
  }

  Future<void> add(Category category) async {
    final current = await future;
    final updated = [...current, category];
    final storage = await ref.read(storageProvider.future);
    await storage.saveCategories(updated);
    state = AsyncData(updated);
  }
}

Snippet newSnippet({
  required String label,
  required String command,
  required String categoryId,
  bool requireConfirm = false,
}) =>
    Snippet(
      id: const Uuid().v4(),
      label: label,
      command: command,
      categoryId: categoryId,
      requireConfirm: requireConfirm,
    );
