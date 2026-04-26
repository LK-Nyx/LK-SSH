import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/toolbar_button.dart';

enum StickyMod { ctrl, alt, shift }

// ignore: avoid_classes_with_only_static_members
final class AnsiService {
  AnsiService._();

  static Uint8List sequenceFor(ToolbarButtonType type) => switch (type) {
    ToolbarButtonType.arrowUp    => _s('\x1b[A'),
    ToolbarButtonType.arrowDown  => _s('\x1b[B'),
    ToolbarButtonType.arrowRight => _s('\x1b[C'),
    ToolbarButtonType.arrowLeft  => _s('\x1b[D'),
    ToolbarButtonType.home       => _s('\x1b[H'),
    ToolbarButtonType.end        => _s('\x1b[F'),
    ToolbarButtonType.pageUp     => _s('\x1b[5~'),
    ToolbarButtonType.pageDown   => _s('\x1b[6~'),
    ToolbarButtonType.del        => _s('\x1b[3~'),
    ToolbarButtonType.esc        => _s('\x1b'),
    ToolbarButtonType.tab        => _s('\t'),
    ToolbarButtonType.f1         => _s('\x1bOP'),
    ToolbarButtonType.f2         => _s('\x1bOQ'),
    ToolbarButtonType.f3         => _s('\x1bOR'),
    ToolbarButtonType.f4         => _s('\x1bOS'),
    ToolbarButtonType.f5         => _s('\x1b[15~'),
    ToolbarButtonType.f6         => _s('\x1b[17~'),
    ToolbarButtonType.f7         => _s('\x1b[18~'),
    ToolbarButtonType.f8         => _s('\x1b[19~'),
    ToolbarButtonType.f9         => _s('\x1b[20~'),
    ToolbarButtonType.f10        => _s('\x1b[21~'),
    ToolbarButtonType.f11        => _s('\x1b[23~'),
    ToolbarButtonType.f12        => _s('\x1b[24~'),
    _                            => Uint8List(0),
  };

  static Uint8List applyMod(String data, StickyMod? mod) {
    if (data.isEmpty) return Uint8List(0);
    if (mod == null) return Uint8List.fromList(utf8.encode(data));
    final code = data.codeUnitAt(0);
    return switch (mod) {
      StickyMod.ctrl  => Uint8List.fromList([code & 0x1F]),
      StickyMod.alt   => Uint8List.fromList([0x1B, ...utf8.encode(data)]),
      StickyMod.shift => Uint8List.fromList(utf8.encode(data.toUpperCase())),
    };
  }

  static Uint8List _s(String seq) => Uint8List.fromList(seq.codeUnits);
}
