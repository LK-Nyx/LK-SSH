import 'package:flutter/material.dart';
// SSHUserInfoRequest is not re-exported by the top-level dartssh2.dart.
// ignore: implementation_imports
import 'package:dartssh2/src/ssh_userauth.dart';

class KeyboardInteractiveSheet extends StatefulWidget {
  const KeyboardInteractiveSheet({super.key, required this.request});
  final SSHUserInfoRequest request;

  static Future<List<String>?> show(
    BuildContext context,
    SSHUserInfoRequest req,
  ) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: KeyboardInteractiveSheet(request: req),
      ),
    );
  }

  @override
  State<KeyboardInteractiveSheet> createState() =>
      _KeyboardInteractiveSheetState();
}

class _KeyboardInteractiveSheetState extends State<KeyboardInteractiveSheet> {
  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      widget.request.prompts.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.request.name.isNotEmpty)
            Text(widget.request.name,
                style: Theme.of(context).textTheme.titleMedium),
          if (widget.request.instruction.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.request.instruction),
          ],
          const SizedBox(height: 12),
          for (int i = 0; i < widget.request.prompts.length; i++) ...[
            TextField(
              controller: _ctrls[i],
              obscureText: !widget.request.prompts[i].echo,
              autofocus: i == 0,
              decoration: InputDecoration(
                labelText: widget.request.prompts[i].promptText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  _ctrls.map((c) => c.text).toList(),
                ),
                child: const Text('Soumettre'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
