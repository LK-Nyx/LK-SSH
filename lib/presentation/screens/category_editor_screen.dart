import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/category.dart';
import '../providers/snippets_provider.dart';

class CategoryEditorScreen extends ConsumerWidget {
  const CategoryEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final snippetsAsync = ref.watch(snippetsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      body: categoriesAsync.when(
        data: (categories) => ReorderableListView.builder(
          itemCount: categories.length,
          onReorder: (oldIndex, newIndex) =>
              ref.read(categoriesNotifierProvider.notifier).reorder(oldIndex, newIndex),
          itemBuilder: (ctx, i) {
            final cat = categories[i];
            final count = snippetsAsync.valueOrNull
                    ?.where((s) => s.categoryId == cat.id)
                    .length ??
                0;
            return ListTile(
              key: ValueKey(cat.id),
              leading: const Icon(Icons.drag_handle, color: Colors.grey),
              title: Text(cat.label,
                  style: const TextStyle(fontFamily: 'monospace')),
              subtitle: Text(
                '$count snippet${count != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onPressed: () => _showRenameDialog(context, ref, cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 18, color: Colors.red),
                    onPressed: () =>
                        _showDeleteDialog(context, ref, cat, count),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final ctrl = TextEditingController(text: cat.label);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .rename(cat.id, result);
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Category cat,
    int snippetCount,
  ) async {
    final msg = snippetCount > 0
        ? 'Supprimer "${cat.label}" ? Les $snippetCount snippet${snippetCount != 1 ? 's' : ''} associé${snippetCount != 1 ? 's' : ''} seront également supprimés.'
        : 'Supprimer la catégorie "${cat.label}" ?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .delete(cat.id);
    }
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ex: Monitoring',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(categoriesNotifierProvider.notifier).add(
            Category(id: const Uuid().v4(), label: result),
          );
    }
  }
}
