import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/ansi_service.dart';

part 'keyboard_toolbar_provider.g.dart';

class KeyboardToolbarState {
  const KeyboardToolbarState({this.activeMod, this.editMode = false});
  final StickyMod? activeMod;
  final bool editMode;
}

@riverpod
class KeyboardToolbar extends _$KeyboardToolbar {
  @override
  KeyboardToolbarState build(String sessionId) =>
      const KeyboardToolbarState();

  void toggleMod(StickyMod mod) {
    state = KeyboardToolbarState(
      activeMod: state.activeMod == mod ? null : mod,
      editMode: state.editMode,
    );
  }

  void clearMod() {
    state = KeyboardToolbarState(editMode: state.editMode);
  }

  void toggleEditMode() {
    state = KeyboardToolbarState(
      activeMod: state.activeMod,
      editMode: !state.editMode,
    );
  }
}
