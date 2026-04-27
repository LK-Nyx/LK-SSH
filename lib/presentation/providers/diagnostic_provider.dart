import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Taille de police temporaire utilisée par DiagnosticRunner pour piloter
/// de vrais changements de layout dans TerminalView (simulation pinch).
/// null = utiliser la taille normale (_pendingSize).
final diagnosticFontSizeProvider = StateProvider<double?>((ref) => null);
