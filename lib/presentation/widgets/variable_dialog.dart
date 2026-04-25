import 'package:flutter/material.dart';

class VariableDialog extends StatefulWidget {
  const VariableDialog({
    super.key,
    required this.templateLabel,
    required this.variables,
  });

  final String templateLabel;
  final List<String> variables;

  @override
  State<VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<VariableDialog> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final v in widget.variables) v: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final values = {
      for (final entry in _controllers.entries) entry.key: entry.value.text.trim(),
    };
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.templateLabel,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.variables
              .map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllers[v],
                    decoration: InputDecoration(
                      labelText: v,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    autofocus: widget.variables.first == v,
                    onSubmitted: (_) {
                      if (widget.variables.last == v) _submit();
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
