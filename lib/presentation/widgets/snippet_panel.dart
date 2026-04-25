import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/snippet.dart';
import '../../domain/services/snippet_service.dart';
import '../providers/snippets_provider.dart';
import '../providers/ssh_provider.dart';
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

    final resolveResult =
        SnippetService.resolve(snippet.command, resolvedVars);
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
    final sshAsync = ref.read(sshNotifierProvider(widget.sessionId));
    sshAsync.whenData((conn) async {
      if (conn == null) return;
      final shellResult = await conn.openShell();
      shellResult.when(
        ok: (shell) {
          shell.write(Uint8List.fromList('$command\n'.codeUnits));
          shell.close();
        },
        err: (_) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final snippetsAsync = ref.watch(snippetsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

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
                            onTap: () => setState(
                                () => _selectedCategoryId = cat.id),
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
                    ],
                  ),
                ),
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
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          children: filtered
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: SnippetChip(
                                    snippet: s,
                                    onTap: () => _executeSnippet(s),
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
}
