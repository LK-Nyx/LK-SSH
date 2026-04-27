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

  Future<void> deleteByCategory(String categoryId) async {
    final current = await future;
    final updated = current.where((s) => s.categoryId != categoryId).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveSnippets(updated);
    state = AsyncData(updated);
  }

  Future<void> reorder(int oldIndex, int newIndex, String categoryId) async {
    final current = await future;
    final inCat = current.where((s) => s.categoryId == categoryId).toList();
    if (newIndex > oldIndex) newIndex--;
    inCat.insert(newIndex, inCat.removeAt(oldIndex));
    // Reconstruire la liste complète en remplaçant les snippets de la catégorie
    // dans leurs positions d'origine.
    int catIdx = 0;
    final result =
        current.map((s) => s.categoryId == categoryId ? inCat[catIdx++] : s).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveSnippets(result);
    state = AsyncData(result);
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

  Future<void> rename(String id, String label) async {
    final current = await future;
    final updated =
        current.map((c) => c.id == id ? c.copyWith(label: label) : c).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveCategories(updated);
    state = AsyncData(updated);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = await future;
    final updated = [...current];
    if (newIndex > oldIndex) newIndex--;
    updated.insert(newIndex, updated.removeAt(oldIndex));
    final storage = await ref.read(storageProvider.future);
    await storage.saveCategories(updated);
    state = AsyncData(updated);
  }

  Future<void> delete(String id) async {
    final current = await future;
    final updated = current.where((c) => c.id != id).toList();
    final storage = await ref.read(storageProvider.future);
    await storage.saveCategories(updated);
    state = AsyncData(updated);
    await ref.read(snippetsNotifierProvider.notifier).deleteByCategory(id);
  }
}

Snippet newSnippet({
  required String label,
  required String command,
  required String categoryId,
  bool requireConfirm = false,
  bool autoExecute = true,
}) =>
    Snippet(
      id: const Uuid().v4(),
      label: label,
      command: command,
      categoryId: categoryId,
      requireConfirm: requireConfirm,
      autoExecute: autoExecute,
    );
