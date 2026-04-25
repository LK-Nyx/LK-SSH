import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../data/models/server.dart';
import '../../data/models/session.dart';
import '../../data/models/settings.dart';
import '../providers/secure_key_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ssh_provider.dart';
import '../providers/terminal_provider.dart';
import '../../domain/services/ssh_service.dart';
import '../widgets/snippet_panel.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({
    super.key,
    required this.initialSessionId,
    required this.initialServer,
  });

  final String initialSessionId;
  final Server initialServer;

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  late String _activeSessionId;

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.initialSessionId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _connect(_activeSessionId, widget.initialServer),
    );
  }

  Future<void> _connect(String sessionId, Server server) async {
    final storage = ref.read(secureKeyStorageProvider);
    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    final keyResult = await storage.loadKey(
      passphrase:
          settings?.keyStorageMode == KeyStorageMode.passphraseProtected
              ? await _askPassphrase()
              : null,
    );
    if (!mounted) return;
    keyResult.when(
      ok: (key) async {
        final result = await ref
            .read(sshNotifierProvider(sessionId).notifier)
            .connect(server, key);
        if (!mounted) return;
        result.when(
          ok: (conn) => _bindTerminal(sessionId, conn),
          err: (e) => _showError(e.toString()),
        );
      },
      err: (e) => _showError(e.toString()),
    );
  }

  Future<String?> _askPassphrase() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Passphrase'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration:
              const InputDecoration(labelText: 'Passphrase clé SSH'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _bindTerminal(String sessionId, SshConnection conn) async {
    final terminal = ref.read(terminalProvider(sessionId));
    final shellResult = await conn.openShell(width: 120, height: 40);
    if (!mounted) return;
    shellResult.when(
      ok: (shell) {
        shell.stdout.listen(
          (data) => terminal.write(String.fromCharCodes(data)),
        );
        shell.stderr.listen(
          (data) => terminal.write(String.fromCharCodes(data)),
        );
        terminal.onOutput = (data) =>
            shell.write(Uint8List.fromList(data.codeUnits));
      },
      err: (e) => _showError(e.toString()),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[900],
      ),
    );
  }

  void _openNewSession() {
    final server = widget.initialServer;
    final newId = ref
        .read(sessionsNotifierProvider.notifier)
        .open(server.id, server.label);
    setState(() => _activeSessionId = newId);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _connect(newId, server),
    );
  }

  void _closeSession(String id) {
    final sessions = ref.read(sessionsNotifierProvider);
    ref.read(sshNotifierProvider(id).notifier).disconnect();
    ref.read(sessionsNotifierProvider.notifier).close(id);
    if (_activeSessionId == id) {
      final remaining = sessions.where((s) => s.id != id).toList();
      if (remaining.isEmpty) {
        Navigator.pop(context);
      } else {
        setState(() => _activeSessionId = remaining.first.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsNotifierProvider);
    final activeSession = sessions.firstWhere(
      (s) => s.id == _activeSessionId,
      orElse: () => Session(
        id: _activeSessionId,
        serverId: widget.initialServer.id,
        label: widget.initialServer.label,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SessionTabBar(
              sessions: sessions,
              activeId: _activeSessionId,
              onSelect: (id) => setState(() => _activeSessionId = id),
              onAdd: _openNewSession,
              onClose: _closeSession,
            ),
            Expanded(
              child: _TerminalView(sessionId: _activeSessionId),
            ),
            SnippetPanel(
              sessionId: _activeSessionId,
              serverId: activeSession.serverId,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTabBar extends StatelessWidget {
  const _SessionTabBar({
    required this.sessions,
    required this.activeId,
    required this.onSelect,
    required this.onAdd,
    required this.onClose,
  });

  final List<Session> sessions;
  final String activeId;
  final void Function(String) onSelect;
  final VoidCallback onAdd;
  final void Function(String) onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: sessions.map((s) {
                final isActive = s.id == activeId;
                return GestureDetector(
                  onTap: () => onSelect(s.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive
                              ? const Color(0xFF00FF41)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _StatusDot(status: s.status),
                        const SizedBox(width: 4),
                        Text(
                          s.label,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isActive ? Colors.white : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => onClose(s.id),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16, color: Color(0xFF00FF41)),
            onPressed: onAdd,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final SessionStatus status;

  Color get _color => switch (status) {
        SessionStatus.connected => const Color(0xFF00FF41),
        SessionStatus.error => Colors.red,
        SessionStatus.disconnected => Colors.grey,
        SessionStatus.connecting => Colors.orange,
      };

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      );
}

class _TerminalView extends ConsumerWidget {
  const _TerminalView({required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminal = ref.watch(terminalProvider(sessionId));
    return TerminalView(
      terminal,
      theme: const TerminalTheme(
        cursor: Color(0xFF00FF41),
        selection: Color(0x5000FF41),
        foreground: Color(0xFFCCCCCC),
        background: Color(0xFF0D0D0D),
        black: Color(0xFF000000),
        red: Color(0xFFCC0000),
        green: Color(0xFF00CC44),
        yellow: Color(0xFFCCAA00),
        blue: Color(0xFF0044CC),
        magenta: Color(0xFFCC00CC),
        cyan: Color(0xFF00AACC),
        white: Color(0xFFCCCCCC),
        brightBlack: Color(0xFF555555),
        brightRed: Color(0xFFFF4444),
        brightGreen: Color(0xFF00FF41),
        brightYellow: Color(0xFFFFDD00),
        brightBlue: Color(0xFF4488FF),
        brightMagenta: Color(0xFFFF44FF),
        brightCyan: Color(0xFF44DDFF),
        brightWhite: Color(0xFFFFFFFF),
        searchHitBackground: Color(0x4000FF41),
        searchHitBackgroundCurrent: Color(0x8000FF41),
        searchHitForeground: Color(0xFF000000),
      ),
    );
  }
}
