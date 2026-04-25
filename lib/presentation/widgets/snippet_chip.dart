import 'package:flutter/material.dart';

import '../../data/models/snippet.dart';

class SnippetChip extends StatelessWidget {
  const SnippetChip({
    super.key,
    required this.snippet,
    required this.onTap,
  });

  final Snippet snippet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border.all(
            color: snippet.requireConfirm
                ? Colors.orange.withValues(alpha: 0.6)
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
  }
}
