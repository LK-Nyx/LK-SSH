import 'package:freezed_annotation/freezed_annotation.dart';

part 'toolbar_button.freezed.dart';
part 'toolbar_button.g.dart';

enum ToolbarButtonType {
  ctrl, alt, shift,
  esc, tab,
  arrowUp, arrowDown, arrowLeft, arrowRight,
  home, end, pageUp, pageDown,
  del,
  f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,
  password,
}

@freezed
class ToolbarButton with _$ToolbarButton {
  const factory ToolbarButton({
    required ToolbarButtonType type,
    String? label,
  }) = _ToolbarButton;

  factory ToolbarButton.fromJson(Map<String, dynamic> json) =>
      _$ToolbarButtonFromJson(json);
}

List<ToolbarButton> defaultToolbarButtons() => const [
  ToolbarButton(type: ToolbarButtonType.ctrl),
  ToolbarButton(type: ToolbarButtonType.alt),
  ToolbarButton(type: ToolbarButtonType.shift),
  ToolbarButton(type: ToolbarButtonType.esc),
  ToolbarButton(type: ToolbarButtonType.tab),
  ToolbarButton(type: ToolbarButtonType.arrowUp),
  ToolbarButton(type: ToolbarButtonType.arrowDown),
  ToolbarButton(type: ToolbarButtonType.arrowLeft),
  ToolbarButton(type: ToolbarButtonType.arrowRight),
  ToolbarButton(type: ToolbarButtonType.home),
  ToolbarButton(type: ToolbarButtonType.end),
  ToolbarButton(type: ToolbarButtonType.pageUp),
  ToolbarButton(type: ToolbarButtonType.pageDown),
  ToolbarButton(type: ToolbarButtonType.del),
  ToolbarButton(type: ToolbarButtonType.password),
  ToolbarButton(type: ToolbarButtonType.f1),
  ToolbarButton(type: ToolbarButtonType.f2),
  ToolbarButton(type: ToolbarButtonType.f3),
  ToolbarButton(type: ToolbarButtonType.f4),
  ToolbarButton(type: ToolbarButtonType.f5),
  ToolbarButton(type: ToolbarButtonType.f6),
  ToolbarButton(type: ToolbarButtonType.f7),
  ToolbarButton(type: ToolbarButtonType.f8),
  ToolbarButton(type: ToolbarButtonType.f9),
  ToolbarButton(type: ToolbarButtonType.f10),
  ToolbarButton(type: ToolbarButtonType.f11),
  ToolbarButton(type: ToolbarButtonType.f12),
];
