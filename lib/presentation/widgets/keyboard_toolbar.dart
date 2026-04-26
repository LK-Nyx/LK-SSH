// lib/presentation/widgets/keyboard_toolbar.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/settings.dart';
import '../../data/models/toolbar_button.dart';
import '../../data/ssh/toolbar_password_storage.dart';
import '../../domain/services/ansi_service.dart';
import '../providers/keyboard_toolbar_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ssh_provider.dart';

class KeyboardToolbar extends ConsumerStatefulWidget {
  const KeyboardToolbar({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<KeyboardToolbar> createState() => _KeyboardToolbarState();
}

class _KeyboardToolbarState extends ConsumerState<KeyboardToolbar> {
  String? _password;
  final _pwStorage = ToolbarPasswordStorage();
  List<ToolbarButton>? _localButtons;

  @override
  void initState() {
    super.initState();
    _pwStorage.load().then((pw) {
      if (mounted) setState(() => _password = pw);
    });
  }

  List<ToolbarButton> _buttons(Settings? settings) {
    if (_localButtons != null) return _localButtons!;
    final list = settings?.toolbarButtons ?? [];
    return list.isEmpty ? defaultToolbarButtons() : list;
  }

  bool _isModifier(ToolbarButtonType t) =>
      t == ToolbarButtonType.ctrl ||
      t == ToolbarButtonType.alt ||
      t == ToolbarButtonType.shift;

  StickyMod? _modFor(ToolbarButtonType t) => switch (t) {
    ToolbarButtonType.ctrl  => StickyMod.ctrl,
    ToolbarButtonType.alt   => StickyMod.alt,
    ToolbarButtonType.shift => StickyMod.shift,
    _ => null,
  };

  void _onTap(ToolbarButtonType type) {
    final notifier = ref.read(keyboardToolbarProvider(widget.sessionId).notifier);
    final mod = _modFor(type);
    if (mod != null) { notifier.toggleMod(mod); return; }
    if (type == ToolbarButtonType.password) {
      final pw = _password;
      if (pw != null && pw.isNotEmpty) {
        ref.read(sshNotifierProvider(widget.sessionId)).whenData(
          (conn) => conn?.sendRaw(Uint8List.fromList(utf8.encode('$pw\n'))),
        );
      }
      return;
    }
    final bytes = AnsiService.sequenceFor(type);
    if (bytes.isNotEmpty) {
      ref.read(sshNotifierProvider(widget.sessionId)).whenData(
        (conn) => conn?.sendRaw(bytes),
      );
    }
  }

  void _onDelete(int index, List<ToolbarButton> buttons, Settings settings) {
    final updated = [...buttons]..removeAt(index);
    setState(() => _localButtons = updated);
    ref.read(settingsNotifierProvider.notifier)
        .save(settings.copyWith(toolbarButtons: updated));
  }

  void _onReorder(int oldIndex, int newIndex, List<ToolbarButton> buttons, Settings settings) {
    final updated = [...buttons];
    if (newIndex > oldIndex) newIndex--;
    updated.insert(newIndex, updated.removeAt(oldIndex));
    setState(() => _localButtons = updated);
    ref.read(settingsNotifierProvider.notifier)
        .save(settings.copyWith(toolbarButtons: updated));
  }

  void _showAddSheet(List<ToolbarButton> current, Settings settings) {
    final currentTypes = current.map((b) => b.type).toSet();
    final available = defaultToolbarButtons()
        .where((b) => !currentTypes.contains(b.type))
        .toList();
    if (available.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Ajouter un bouton',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: available.map((btn) => ListTile(
                title: Text(_labelFor(btn.type),
                    style: const TextStyle(fontFamily: 'monospace')),
                onTap: () {
                  ref.read(settingsNotifierProvider.notifier).save(
                    settings.copyWith(toolbarButtons: [...current, btn]),
                  );
                  Navigator.pop(context);
                },
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(ToolbarButtonType type) => switch (type) {
    ToolbarButtonType.ctrl       => 'Ctrl',
    ToolbarButtonType.alt        => 'Alt',
    ToolbarButtonType.shift      => 'Shift',
    ToolbarButtonType.esc        => 'Esc',
    ToolbarButtonType.tab        => 'Tab',
    ToolbarButtonType.arrowUp    => '↑',
    ToolbarButtonType.arrowDown  => '↓',
    ToolbarButtonType.arrowLeft  => '←',
    ToolbarButtonType.arrowRight => '→',
    ToolbarButtonType.home       => 'Home',
    ToolbarButtonType.end        => 'End',
    ToolbarButtonType.pageUp     => 'PgUp',
    ToolbarButtonType.pageDown   => 'PgDn',
    ToolbarButtonType.del        => 'Del',
    ToolbarButtonType.f1         => 'F1',
    ToolbarButtonType.f2         => 'F2',
    ToolbarButtonType.f3         => 'F3',
    ToolbarButtonType.f4         => 'F4',
    ToolbarButtonType.f5         => 'F5',
    ToolbarButtonType.f6         => 'F6',
    ToolbarButtonType.f7         => 'F7',
    ToolbarButtonType.f8         => 'F8',
    ToolbarButtonType.f9         => 'F9',
    ToolbarButtonType.f10        => 'F10',
    ToolbarButtonType.f11        => 'F11',
    ToolbarButtonType.f12        => 'F12',
    ToolbarButtonType.password   => '🔑',
  };

  Widget _buildButton({
    required ToolbarButton btn,
    required bool isActive,
    required bool editMode,
    required int index,
    required List<ToolbarButton> buttons,
    required Settings settings,
  }) {
    final label = btn.label ?? _labelFor(btn.type);
    return GestureDetector(
      key: ValueKey(btn.type),
      onTap: editMode ? null : () => _onTap(btn.type),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00FF41) : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isActive ? Colors.black : Colors.white,
              ),
            ),
          ),
          if (editMode)
            Positioned(
              top: 2,
              right: 0,
              child: GestureDetector(
                onTap: () => _onDelete(index, buttons, settings),
                child: const CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 9, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsNotifierProvider.select((s) => s.valueOrNull?.toolbarButtons),
      (_, __) { if (_localButtons != null) setState(() => _localButtons = null); },
    );

    final settings = ref.watch(settingsNotifierProvider).valueOrNull;
    final toolbarState = ref.watch(keyboardToolbarProvider(widget.sessionId));
    final buttons = _buttons(settings);
    final editMode = toolbarState.editMode;
    final activeMod = toolbarState.activeMod;
    final fixedNav = settings?.fixedNavSection ?? false;

    final currentTypes = buttons.map((b) => b.type).toSet();
    final hasAvailableButtons = defaultToolbarButtons()
        .any((b) => !currentTypes.contains(b.type));

    const navTypes = {
      ToolbarButtonType.arrowUp, ToolbarButtonType.arrowDown,
      ToolbarButtonType.arrowLeft, ToolbarButtonType.arrowRight,
      ToolbarButtonType.esc, ToolbarButtonType.tab,
    };

    final navButtons = fixedNav && !editMode
        ? buttons.where((b) => navTypes.contains(b.type)).toList()
        : <ToolbarButton>[];
    final scrollButtons = fixedNav && !editMode
        ? buttons.where((b) => !navTypes.contains(b.type)).toList()
        : buttons;

    Widget buildBtn(ToolbarButton btn, int globalIndex) => _buildButton(
      btn: btn,
      isActive: _isModifier(btn.type) && _modFor(btn.type) == activeMod,
      editMode: editMode,
      index: globalIndex,
      buttons: buttons,
      settings: settings ?? const Settings(),
    );

    final Widget scrollable = editMode
        ? ReorderableListView(
            scrollDirection: Axis.horizontal,
            onReorder: (o, n) =>
                _onReorder(o, n, buttons, settings ?? const Settings()),
            children: [
              for (int i = 0; i < buttons.length; i++) buildBtn(buttons[i], i),
            ],
          )
        : ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < scrollButtons.length; i++)
                buildBtn(scrollButtons[i], buttons.indexOf(scrollButtons[i])),
            ],
          );

    return GestureDetector(
      onLongPress: () => ref
          .read(keyboardToolbarProvider(widget.sessionId).notifier)
          .toggleEditMode(),
      child: Container(
        height: 44,
        color: editMode ? const Color(0xFF252525) : const Color(0xFF1A1A1A),
        child: fixedNav && !editMode && navButtons.isNotEmpty
            ? Row(
                children: [
                  Row(
                    children: navButtons
                        .map((b) => buildBtn(b, buttons.indexOf(b)))
                        .toList(),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFF3A3A3A)),
                  Expanded(child: scrollable),
                ],
              )
            : Row(
                children: [
                  Expanded(child: scrollable),
                  if (editMode && hasAvailableButtons)
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFF00FF41)),
                      onPressed: () =>
                          _showAddSheet(buttons, settings ?? const Settings()),
                    ),
                ],
              ),
      ),
    );
  }
}
