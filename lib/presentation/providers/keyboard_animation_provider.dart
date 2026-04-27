import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True pendant l'animation du clavier (ouverture / fermeture).
/// Mis à jour par _TerminalBottomBar via didChangeDependencies + debounce.
/// Permet à _TerminalViewState de désactiver autoResize pendant l'animation
/// afin qu'aucun terminal.resize() ne soit émis frame par frame.
final isKeyboardAnimatingProvider = StateProvider<bool>((ref) => false);
