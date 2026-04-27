import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import 'debug_log_service.dart';
import '../../presentation/providers/diagnostic_provider.dart';
import '../../presentation/providers/ssh_provider.dart';
import '../../presentation/providers/terminal_provider.dart';

class DiagnosticRunner {
  DiagnosticRunner(this._ref, this._sessionId);

  final WidgetRef _ref;
  final String _sessionId;
  final _log = DebugLogService.instance;

  Future<void> run() async {
    _log.log('DIAG', '════════ DÉBUT DIAGNOSTIC ════════');

    final conn = _ref.read(sshNotifierProvider(_sessionId)).valueOrNull;
    if (conn == null) {
      _log.log('DIAG', 'ERREUR: conn=NULL — session SSH inactive');
      return;
    }

    final terminal = _ref.read(terminalProvider(_sessionId));

    // ── 1. Flèches ──────────────────────────────────────────────────────────
    _log.log('DIAG', '── Test flèches ──');
    final arrows = <String, List<int>>{
      'UP':    [0x1B, 0x5B, 0x41],
      'DOWN':  [0x1B, 0x5B, 0x42],
      'RIGHT': [0x1B, 0x5B, 0x43],
      'LEFT':  [0x1B, 0x5B, 0x44],
    };
    for (final entry in arrows.entries) {
      conn.sendRaw(Uint8List.fromList(entry.value));
      _log.log('DIAG', '→ ${entry.key} envoyé: ${entry.value}');
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // ── 2. Commandes ────────────────────────────────────────────────────────
    const commands = [
      'ls',
      'clear',
      'notify-send "LK-SSH Test" "Diagnostic OK"',
      'sudo ls',
    ];
    for (final cmd in commands) {
      _log.log('DIAG', '── Commande: $cmd ──');
      conn.sendCommand(cmd);
      await Future.delayed(const Duration(milliseconds: 900));
      _dumpVisible(terminal, 'après "$cmd"');
    }

    // ── 3. Zoom ─────────────────────────────────────────────────────────────
    // diagnosticFontSizeProvider → rebuild _TerminalViewState → TerminalView
    // recalcule les cellules → performLayout → _resizeTerminalIfNeeded →
    // terminal.resize → notre onResize callback.
    // Délais 15-20ms = 1 frame Flutter à 60fps (équivalent pinch réel).

    _log.log('DIAG', '── ZOOM: départ ──');
    _dumpVisible(terminal, 'T0 départ');

    // Séquences : (taille_px, délai_ms_avant_prochain)
    // 0ms = on n'attend pas (changement dans le même frame ou frame suivant immédiat)

    // Phase A — zoom modéré avec hésitations (comportement habituel)
    await _runSeq('A zoom-modéré', terminal, const [
      (14.8, 25), (15.8, 20), (17.0, 22), (18.5, 20), (20.0, 25),
      (21.5, 20), (22.5, 18),
      (21.0, 90), (22.5, 18), (21.0, 18), // hésitation
      (19.5, 20), (17.5, 20), (15.5, 20), (14.0, 0),
    ]);

    await _pause(300);

    // Phase B — zoom MAX complet (14→28) + oscillations à la limite
    await _runSeq('B zoom-MAX', terminal, const [
      (15.5, 16), (17.5, 15), (19.5, 16), (22.0, 15),
      (24.5, 16), (26.5, 15), (28.0, 0),
      // oscillations au max — la plus grande contrainte pour reflowEnabled
      (27.0, 18), (28.0, 15), (27.5, 18), (28.0, 15),
      (26.0, 18), (28.0, 15), (27.0, 18), (28.0, 0),
      // retour rapide
      (25.0, 16), (22.0, 15), (19.0, 16), (16.0, 15), (14.0, 0),
    ]);

    await _pause(300);

    // Phase C — dézoom MIN complet (14→8) + oscillations à la limite basse
    await _runSeq('C zoom-MIN', terminal, const [
      (13.0, 16), (11.5, 15), (10.0, 16), (9.0, 15), (8.0, 0),
      // oscillations au min
      (8.5, 18), (8.0, 15), (9.0, 18), (8.0, 15),
      (8.5, 18), (8.0, 15), (9.5, 18), (8.0, 0),
      // retour
      (10.0, 16), (12.0, 15), (14.0, 0),
    ]);

    await _pause(300);

    // Phase D — swing complet MAX → MIN → MAX (le plus brutal)
    await _runSeq('D swing-MAX→MIN→MAX', terminal, const [
      // MAX en 5 étapes
      (17.5, 15), (21.5, 15), (25.0, 15), (28.0, 0),
      // MIN depuis MAX en 5 étapes (grand saut)
      (22.0, 15), (16.0, 15), (11.0, 15), (8.0, 0),
      // retour MAX
      (14.0, 15), (20.0, 15), (26.0, 15), (28.0, 0),
      // retour normal
      (22.0, 15), (17.0, 15), (14.0, 0),
    ]);

    await _pause(300);

    // Phase E — séquence chaotique (grands sauts, aucun ordre)
    await _runSeq('E chaotique', terminal, const [
      (8.0,  18), (28.0, 18), (14.0, 18), (22.0, 15),
      (9.0,  18), (25.0, 15), (11.0, 18), (20.0, 18),
      (8.0,  15), (18.0, 18), (27.0, 15), (10.0, 18),
      (24.0, 15), (8.0,  18), (16.0, 18), (28.0, 15),
      (12.0, 18), (8.0,  15), (14.0, 0),
    ]);

    await _pause(300);

    // Phase F — oscillations rapides extrêmes 8↔28 (stress pur, 1 frame chacun)
    await _runSeq('F oscillation-8↔28', terminal, const [
      (28.0, 16), (8.0, 16), (28.0, 16), (8.0, 16),
      (28.0, 16), (8.0, 16), (28.0, 16), (8.0, 16),
      (28.0, 16), (8.0, 16), (28.0, 16), (8.0, 0),
      (14.0, 0),
    ]);

    // Restaurer la taille normale, laisser le temps au PTY debounce
    _ref.read(diagnosticFontSizeProvider.notifier).state = null;
    await _pause(400);

    _dumpVisible(terminal, 'TF final (après toutes les phases)');
    _log.log('DIAG', 'Taille finale: ${terminal.viewWidth}x${terminal.viewHeight}');
    _log.log('DIAG', '════════ FIN DIAGNOSTIC ════════');
  }

  Future<void> _runSeq(
    String phase,
    Terminal terminal,
    List<(double, int)> seq,
  ) async {
    _log.log('DIAG', '── Phase $phase ──');
    for (final (size, delay) in seq) {
      _ref.read(diagnosticFontSizeProvider.notifier).state = size;
      if (delay > 0) await Future.delayed(Duration(milliseconds: delay));
    }
    // Laisser Flutter + debounce PTY finir
    await Future.delayed(const Duration(milliseconds: 150));
    _dumpVisible(terminal, 'phase $phase');
  }

  Future<void> _pause(int ms) =>
      Future.delayed(Duration(milliseconds: ms));

  void _dumpVisible(Terminal terminal, String label) {
    final buf = terminal.buffer;
    if (buf.height == 0) {
      _log.log('DIAG', 'DUMP [$label] — buffer vide');
      return;
    }

    final startLine = buf.scrollBack.clamp(0, buf.height - 1);
    final endLine = buf.height - 1;

    final raw = buf.getText(
      BufferRangeLine(
        CellOffset(0, startLine),
        CellOffset(terminal.viewWidth - 1, endLine),
      ),
    );

    final lines = raw.split('\n');
    _log.log(
      'DIAG',
      'DUMP [$label] — ${terminal.viewWidth}×${terminal.viewHeight} '
      '(${lines.length} lignes):',
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final hex = line.runes
          .take(64)
          .map((r) => r.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      _log.log('DIAG', '  L${i.toString().padLeft(2)}: "${line.trimRight()}"  [hex: $hex]');
    }
  }
}
