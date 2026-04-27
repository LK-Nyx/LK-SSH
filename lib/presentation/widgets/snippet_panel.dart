import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/snippet.dart';
import '../../data/storage/debug_log_service.dart';
import '../../data/storage/diagnostic_runner.dart';
import '../../domain/services/snippet_service.dart';
import '../providers/settings_provider.dart';
import '../providers/snippets_provider.dart';
import '../providers/ssh_provider.dart';
import '../screens/category_editor_screen.dart';
import '../screens/snippet_editor_screen.dart';
import 'confirm_bottom_sheet.dart';
import 'snippet_chip.dart';
import 'variable_dialog.dart';

class SnippetPanel extends ConsumerStatefulWidget {
  const SnippetPanel({
    super.key,
    required this.sessionId,
    required this.serverId,
  });

  final String sessionId;
  final String serverId;

  @override
  ConsumerState<SnippetPanel> createState() => _SnippetPanelState();
}

class _SnippetPanelState extends ConsumerState<SnippetPanel> {
  String? _selectedCategoryId;
  bool _editMode = false;

  Future<void> _executeSnippet(Snippet snippet) async {
    final vars = SnippetService.extractVariables(snippet.command);
    Map<String, String> resolvedVars = {};

    if (vars.isNotEmpty) {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => VariableDialog(
          templateLabel: snippet.label,
          variables: vars,
        ),
      );
      if (result == null) return;
      resolvedVars = result;
    }

    final resolveResult = SnippetService.resolve(snippet.command, resolvedVars);
    if (resolveResult.isErr) return;
    final command = resolveResult.value;

    if (!mounted) return;
    if (snippet.requireConfirm) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        builder: (_) => ConfirmBottomSheet(command: command),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    final log = DebugLogService.instance;
    final sshAsync = ref.read(sshNotifierProvider(widget.sessionId));
    log.log('SNIPPET', 'command="$command" autoExecute=${snippet.autoExecute}');
    sshAsync.whenData((conn) {
      if (conn == null) return;
      if (snippet.autoExecute) {
        conn.sendCommand(command);
      } else {
        conn.sendRaw(Uint8List.fromList(utf8.encode(command)));
      }
    });
  }

  void _openEditor(Snippet snippet) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SnippetEditorScreen(snippet: snippet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snippetsAsync = ref.watch(snippetsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final debugMode = ref.watch(
      settingsNotifierProvider
          .select((s) => s.valueOrNull?.fileDebugMode ?? false),
    );

    return snippetsAsync.when(
      data: (snippets) => categoriesAsync.when(
        data: (categories) {
          _selectedCategoryId ??= categories.firstOrNull?.id;
          final filtered = snippets
              .where((s) => s.categoryId == _selectedCategoryId)
              .toList();

          return Container(
            color: const Color(0xFF111111),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Ligne catégories ──────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    children: [
                      ...categories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategoryId = cat.id;
                              _editMode = false;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedCategoryId == cat.id
                                    ? const Color(0xFF00FF41)
                                        .withValues(alpha: 0.15)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _selectedCategoryId == cat.id
                                      ? const Color(0xFF00FF41)
                                      : const Color(0xFF2A2A2A),
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                cat.label,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: _selectedCategoryId == cat.id
                                      ? const Color(0xFF00FF41)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_editMode)
                        // ✓ Quitter le mode édition
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              size: 16, color: Color(0xFF00FF41)),
                          padding: EdgeInsets.zero,
                          tooltip: 'Terminer',
                          onPressed: () => setState(() => _editMode = false),
                        )
                      else ...[
                        IconButton(
                          icon: const Icon(Icons.add,
                              size: 14, color: Color(0xFF00FF41)),
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => SnippetEditorScreen(
                                defaultCategoryId: _selectedCategoryId,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune,
                              size: 14, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          tooltip: 'Gérer les catégories',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const CategoryEditorScreen(),
                            ),
                          ),
                        ),
                        if (debugMode)
                          IconButton(
                            icon: const Text('🔬',
                                style: TextStyle(fontSize: 14)),
                            padding: EdgeInsets.zero,
                            tooltip: 'Lancer diagnostic',
                            onPressed: () =>
                                DiagnosticRunner(ref, widget.sessionId).run(),
                          ),
                      ],
                    ],
                  ),
                ),
                // ── Ligne snippets ────────────────────────────────────────
                SizedBox(
                  height: 80,
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun snippet — appuyez sur +',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      : _editMode
                          ? _buildEditableList(filtered)
                          : ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              children: filtered
                                  .map(
                                    (s) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: SnippetChip(
                                        key: ValueKey(s.id),
                                        snippet: s,
                                        onTap: () => _executeSnippet(s),
                                        onLongPress: () =>
                                            setState(() => _editMode = true),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEditableList(List<Snippet> filtered) {
    return ReorderableListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        final catId = _selectedCategoryId;
        if (catId != null) {
          ref
              .read(snippetsNotifierProvider.notifier)
              .reorder(oldIndex, newIndex, catId);
        }
      },
      children: [
        for (int i = 0; i < filtered.length; i++)
          Padding(
            key: ValueKey(filtered[i].id),
            padding: const EdgeInsets.only(right: 6),
            child: ReorderableDragStartListener(
              index: i,
              // long press sur le chip → déplacer ; tap → ouvrir l'éditeur
              child: SnippetChip(
                snippet: filtered[i],
                editMode: true,
                onTap: () => _openEditor(filtered[i]),
                onDelete: () => ref
                    .read(snippetsNotifierProvider.notifier)
                    .delete(filtered[i].id),
              ),
            ),
          ),
      ],
    );
  }
}
