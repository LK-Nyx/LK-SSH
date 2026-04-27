import 'package:flutter/material.dart';

import '../../data/models/snippet.dart';

class SnippetChip extends StatelessWidget {
  const SnippetChip({
    super.key,
    required this.snippet,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.editMode = false,
  });

  final Snippet snippet;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final chip = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border.all(
            color: snippet.requireConfirm
                ? Colors.orange.withValues(alpha: 0.6)
                : !snippet.autoExecute
                    ? Colors.blue.withValues(alpha: 0.5)
                    : const Color(0xFF2A2A2A),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (snippet.requireConfirm) ...[
              const Icon(Icons.warning_amber, size: 12, color: Colors.orange),
              const SizedBox(width: 4),
            ] else if (!snippet.autoExecute) ...[
              const Icon(Icons.edit_note, size: 12, color: Colors.blue),
              const SizedBox(width: 4),
            ],
            Text(
              snippet.label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
      ),
    );

    if (!editMode || onDelete == null) return chip;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        chip,
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            onTap: onDelete,
            child: const CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
