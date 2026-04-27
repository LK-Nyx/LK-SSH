import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../data/models/auth_prompt_request.dart';
import '../../data/models/server.dart';
import '../../data/models/session.dart';
import '../providers/diagnostic_provider.dart';
import '../providers/keyboard_animation_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ssh_provider.dart';
import '../widgets/host_key_mismatch_sheet.dart';
import '../widgets/keyboard_interactive_sheet.dart';
import '../widgets/password_prompt_sheet.dart';
import '../providers/terminal_provider.dart';
import '../../data/storage/debug_log_service.dart';
import '../../domain/services/ansi_service.dart';
import '../../domain/services/ssh_service.dart';
import '../providers/keyboard_toolbar_provider.dart' hide KeyboardToolbar;
import '../widgets/keyboard_toolbar.dart';
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
  Timer? _ptyDebounce;
  final _inactivityTimers = <String, Timer>{};
  final _promptSubs = <String, StreamSubscription<AuthPromptRequest>>{};

  @override
  void dispose() {
    _ptyDebounce?.cancel();
    for (final t in _inactivityTimers.values) { t.cancel(); }
    for (final s in _promptSubs.values) { s.cancel(); }
    super.dispose();
  }

  Future<void> _handlePrompt(AuthPromptRequest req) async {
    if (!mounted) return;
    switch (req) {
      case PasswordPromptRequest():
        final pwd = await PasswordPromptSheet.show(
          context,
          user: req.user,
          host: req.host,
        );
        if (!req.completer.isCompleted) req.completer.complete(pwd);
      case KbInteractivePromptRequest():
        final answers =
            await KeyboardInteractiveSheet.show(context, req.request);
        if (!req.completer.isCompleted) req.completer.complete(answers);
      case HostKeyMismatchRequest():
        final decision =
            await HostKeyMismatchSheet.show(context, req.change);
        if (!req.completer.isCompleted) req.completer.complete(decision);
    }
  }

  void _resetInactivityTimer(String sessionId) {
    _inactivityTimers[sessionId]?.cancel();
    final minutes = ref.read(settingsNotifierProvider).valueOrNull?.sessionTimeoutMinutes ?? 5;
    if (minutes <= 0) return;
    _inactivityTimers[sessionId] = Timer(Duration(minutes: minutes), () {
      _inactivityTimers.remove(sessionId);
      if (!mounted) return;
      _log(sessionId, 'Timeout d\'inactivité ($minutes min) — déconnexion');
      ref.read(sshNotifierProvider(sessionId).notifier).disconnect();
    });
  }

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.initialSessionId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _connect(_activeSessionId, widget.initialServer),
    );
  }

  bool get _verbose =>
      ref.read(settingsNotifierProvider).valueOrNull?.verboseLogging ?? false;

  void _log(String sessionId, String msg, {bool verboseOnly = false}) {
    if (verboseOnly && !_verbose) return;
    final terminal = ref.read(terminalProvider(sessionId));
    terminal.write('\x1b[33m[lk-ssh] $msg\x1b[0m\r\n');
  }

  void _logOk(String sessionId, String msg) {
    final terminal = ref.read(terminalProvider(sessionId));
    terminal.write('\x1b[32m[ok] $msg\x1b[0m\r\n');
  }

  Future<void> _connect(String sessionId, Server server) async {
    _log(sessionId, 'Connexion à ${server.host}:${server.port} (${server.username})…');
    _log(sessionId, 'Handshake SSH…', verboseOnly: true);
    final notifier = ref.read(sshNotifierProvider(sessionId).notifier);
    _promptSubs[sessionId] ??= notifier.prompts.listen(_handlePrompt);
    final result = await notifier.connect(server);
    if (!mounted) return;
    result.when(
      ok: (conn) {
        _log(sessionId, 'Authentifié', verboseOnly: true);
        _log(sessionId, 'Ouverture du shell PTY (120×40)…', verboseOnly: true);
        _bindTerminal(sessionId, conn);
      },
      err: (e) => _showError(e.message),
    );
  }

  Future<void> _bindTerminal(String sessionId, SshConnection conn) async {
    final terminal = ref.read(terminalProvider(sessionId));
    final shellResult = await conn.openShell(width: 120, height: 40);
    if (!mounted) return;
    shellResult.when(
      ok: (shell) {
        _logOk(sessionId, 'Shell prêt — ${conn.server.host}');
        shell.stdout.listen(
          (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        );
        shell.stderr.listen(
          (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
        );
        terminal.onOutput = (data) {
          _resetInactivityTimer(sessionId);
          final mod =
              ref.read(keyboardToolbarProvider(sessionId)).activeMod;
          final bytes = AnsiService.applyMod(data, mod);
          if (mod != null) {
            ref
                .read(keyboardToolbarProvider(sessionId).notifier)
                .clearMod();
          }
          shell.write(bytes);
        };
        terminal.onResize = (cols, rows, pixelWidth, pixelHeight) {
          DebugLogService.instance.log('PTY', 'onResize: ${cols}x$rows (px: ${pixelWidth}x$pixelHeight)');
          terminal.reflowEnabled = false;
          _ptyDebounce?.cancel();
          _ptyDebounce = Timer(const Duration(milliseconds: 50), () {
            DebugLogService.instance.log('PTY', 'resizeTerminal → ${cols}x$rows');
            shell.resizeTerminal(cols, rows);
            terminal.reflowEnabled = true;
          });
        };
        // xterm peut avoir redimensionné AVANT que onResize soit défini
        // (autoResize tire pendant le premier layout, avant que openShell finisse).
        // On synchro la taille réelle après le prochain frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            DebugLogService.instance.log('PTY', 'postFrameSync: viewWidth=${terminal.viewWidth} viewHeight=${terminal.viewHeight}');
            shell.resizeTerminal(terminal.viewWidth, terminal.viewHeight);
          }
        });
        shell.done.then((_) {
          _inactivityTimers.remove(sessionId)?.cancel();
          if (mounted) _showError('Session terminée par le serveur');
        });
        _resetInactivityTimer(sessionId);
      },
      err: (e) => _showError(e.toString()),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    final terminal = ref.read(terminalProvider(_activeSessionId));
    terminal.write('\r\n\x1b[31m[ERREUR] $msg\x1b[0m\r\n');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[900],
        duration: const Duration(seconds: 8),
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
    _promptSubs.remove(id)?.cancel();
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

    // Layout classique : le Scaffold shrink le body quand le clavier s'ouvre
    // → le PTY reste toujours correctement dimensionné sur la zone visible.
    // RepaintBoundary isole le terminal des repaints de la barre basse.
    // _TerminalBottomBar gère isKeyboardAnimatingProvider pour bloquer
    // autoResize frame-par-frame et éviter les 3 fps pendant l'animation.
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
              child: RepaintBoundary(
                child: _TerminalView(sessionId: _activeSessionId),
              ),
            ),
            _TerminalBottomBar(
              sessionId: _activeSessionId,
              serverId: activeSession.serverId,
            ),
          ],
        ),
      ),
    );
  }
}

// _TerminalBottomBar est ConsumerStatefulWidget pour deux raisons :
// 1. didChangeDependencies détecte les changements de viewInsets (animation
//    du clavier) et met à jour isKeyboardAnimatingProvider — ce qui permet
//    à _TerminalViewState de bloquer autoResize pendant l'animation et donc
//    d'éviter les terminal.resize() (et repaints) frame par frame.
// 2. Le build lui-même lit viewInsets pour masquer le SnippetPanel en paysage.
class _TerminalBottomBar extends ConsumerStatefulWidget {
  const _TerminalBottomBar({
    required this.sessionId,
    required this.serverId,
  });

  final String sessionId;
  final String serverId;

  @override
  ConsumerState<_TerminalBottomBar> createState() => _TerminalBottomBarState();
}

class _TerminalBottomBarState extends ConsumerState<_TerminalBottomBar> {
  Timer? _animDebounce;
  // Initialisé à -1 pour que la première vraie valeur (0 ou plus) soit
  // toujours détectée comme un changement.
  double _lastInset = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset == _lastInset) return;
    _lastInset = inset;
    // On ne peut pas écrire dans un provider pendant le build ;
    // on diffère au frame suivant via postFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(isKeyboardAnimatingProvider.notifier).state = true;
      _animDebounce?.cancel();
      _animDebounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) {
          ref.read(isKeyboardAnimatingProvider.notifier).state = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _animDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenH = MediaQuery.sizeOf(context).height;
    // TabBar(40) + KeyboardToolbar(44) + SnippetPanel(116) + terminal min(60)
    final showSnippets = (screenH - keyboardInset) > 260;
    final toolbarEditMode = ref.watch(
      keyboardToolbarProvider(widget.sessionId).select((s) => s.editMode),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TapRegion(
          enabled: toolbarEditMode,
          onTapOutside: (_) => ref
              .read(keyboardToolbarProvider(widget.sessionId).notifier)
              .toggleEditMode(),
          child: KeyboardToolbar(sessionId: widget.sessionId),
        ),
        if (showSnippets)
          SnippetPanel(sessionId: widget.sessionId, serverId: widget.serverId),
      ],
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

class _TerminalView extends ConsumerStatefulWidget {
  const _TerminalView({required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<_TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends ConsumerState<_TerminalView> {
  double _pendingSize = 14.0;
  Timer? _debounce;
  final _controller = TerminalController(selectionMode: SelectionMode.line);
  final _contextMenuController = ContextMenuController();

  // Pinch zoom — Listener ne participe pas à l'arène de gestes
  final _pointers = <int, Offset>{};
  double? _pinchStartDistance;
  double _pinchStartSize = 14.0;

  @override
  void initState() {
    super.initState();
    final fontSize = ref
            .read(settingsNotifierProvider)
            .valueOrNull
            ?.terminalFontSize ??
        14.0;
    _pendingSize = fontSize;
    _pinchStartSize = fontSize;

    // autofocus: true → le clavier s'ouvre immédiatement au montage.
    // On bloque autoResize dès le 1er frame pour qu'aucun terminal.resize()
    // ne soit émis pendant l'animation initiale du clavier.
    // _TerminalBottomBar.didChangeDependencies() prendra le relais et
    // réinitialisera isKeyboardAnimatingProvider quand le clavier sera stable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(isKeyboardAnimatingProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _contextMenuController.remove();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 2) {
      final positions = _pointers.values.toList();
      _pinchStartDistance = (positions[0] - positions[1]).distance;
      _pinchStartSize = _pendingSize;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length < 2 ||
        _pinchStartDistance == null ||
        _pinchStartDistance! < 1.0) {
      return;
    }
    final positions = _pointers.values.toList();
    final dist = (positions[0] - positions[1]).distance;
    final next = (_pinchStartSize * (dist / _pinchStartDistance!)).clamp(8.0, 28.0);
    if ((next - _pendingSize).abs() < 0.3) return;
    setState(() => _pendingSize = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _debounce = null;
      final s = ref.read(settingsNotifierProvider).valueOrNull;
      if (s == null || !mounted) return;
      ref.read(settingsNotifierProvider.notifier)
          .save(s.copyWith(terminalFontSize: _pendingSize));
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) _pinchStartDistance = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) _pinchStartDistance = null;
  }

  void _showContextMenu({
    required Offset position,
    String? selectedText,
    String? clipText,
  }) {
    final conn = ref.read(sshNotifierProvider(widget.sessionId)).valueOrNull;
    final items = [
      if (selectedText != null)
        ContextMenuButtonItem(
          label: 'Copier',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: selectedText));
            _controller.clearSelection();
            _contextMenuController.remove();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copié'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      if (clipText != null && clipText.isNotEmpty)
        ContextMenuButtonItem(
          label: 'Coller',
          onPressed: () {
            conn?.sendRaw(Uint8List.fromList(utf8.encode(clipText)));
            _contextMenuController.remove();
          },
        ),
    ];
    if (items.isEmpty) return;
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (_) => AdaptiveTextSelectionToolbar.buttonItems(
        anchors: TextSelectionToolbarAnchors(primaryAnchor: position),
        buttonItems: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsNotifierProvider
          .select((s) => s.valueOrNull?.terminalFontSize ?? 14.0),
      (prev, next) {
        if (_debounce == null && _pinchStartDistance == null) {
          setState(() => _pendingSize = next);
        }
      },
    );

    ref.watch(sshNotifierProvider(widget.sessionId));
    final terminal = ref.watch(terminalProvider(widget.sessionId));
    final diagSize = ref.watch(diagnosticFontSizeProvider);
    final effectiveSize = diagSize ?? _pendingSize;
    // autoResize: false pendant le zoom ou l'animation du clavier.
    // → aucun terminal.resize() frame par frame → aucun repaint frame par frame.
    // Un seul resize est émis quand autoResize repasse à true.
    final isZooming = _pinchStartDistance != null || diagSize != null;
    final isKeyboardAnimating = ref.watch(isKeyboardAnimatingProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: TerminalView(
        terminal,
        controller: _controller,
        autofocus: true,
        autoResize: !isZooming && !isKeyboardAnimating,
        textStyle: TerminalStyle(fontSize: effectiveSize),
        onSecondaryTapDown: (details, offset) async {
          _contextMenuController.remove();
          final selection = _controller.selection;
          final selectedText = selection != null
              ? terminal.buffer.getText(selection).trim()
              : null;
          final clip = await Clipboard.getData(Clipboard.kTextPlain);
          _showContextMenu(
            position: details.globalPosition,
            selectedText: (selectedText?.isEmpty ?? true) ? null : selectedText,
            clipText: clip?.text,
          );
        },
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
      ),
    );
  }
}
