import 'package:flutter/material.dart';

import '../../data/models/auth_prompt_request.dart';

class HostKeyMismatchSheet extends StatefulWidget {
  const HostKeyMismatchSheet({super.key, required this.change});
  final HostKeyChange change;

  static Future<HostKeyDecision> show(
    BuildContext context,
    HostKeyChange change,
  ) {
    return showModalBottomSheet<HostKeyDecision>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => HostKeyMismatchSheet(change: change),
    ).then((v) => v ?? HostKeyDecision.reject);
  }

  @override
  State<HostKeyMismatchSheet> createState() => _HostKeyMismatchSheetState();
}

class _HostKeyMismatchSheetState extends State<HostKeyMismatchSheet> {
  bool _detailsOpen = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.change;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Empreinte du serveur changée !',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${c.host}:${c.port}\n\n"
            "L'empreinte du serveur a changé depuis la dernière connexion. "
            "Cela peut indiquer un changement légitime du serveur (réinstallation, "
            "rotation de clé) ou une attaque MitM.",
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _detailsOpen = !_detailsOpen),
            child: Text(
              _detailsOpen ? 'Masquer les détails' : 'Voir les détails',
            ),
          ),
          if (_detailsOpen) ...[
            const SizedBox(height: 4),
            _Fp(label: 'Ancienne', value: c.oldFingerprint),
            const SizedBox(height: 8),
            _Fp(label: 'Nouvelle', value: c.newFingerprint),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, HostKeyDecision.reject),
            child: const Text('Annuler la connexion'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () =>
                Navigator.pop(context, HostKeyDecision.acceptAndPin),
            child: const Text('Faire confiance à la nouvelle empreinte'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Fp extends StatelessWidget {
  const _Fp({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
