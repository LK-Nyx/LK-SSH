// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toolbar_button.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ToolbarButtonImpl _$$ToolbarButtonImplFromJson(Map<String, dynamic> json) =>
    _$ToolbarButtonImpl(
      type: $enumDecode(_$ToolbarButtonTypeEnumMap, json['type']),
      label: json['label'] as String?,
    );

Map<String, dynamic> _$$ToolbarButtonImplToJson(_$ToolbarButtonImpl instance) =>
    <String, dynamic>{
      'type': _$ToolbarButtonTypeEnumMap[instance.type]!,
      'label': instance.label,
    };

const _$ToolbarButtonTypeEnumMap = {
  ToolbarButtonType.ctrl: 'ctrl',
  ToolbarButtonType.alt: 'alt',
  ToolbarButtonType.shift: 'shift',
  ToolbarButtonType.esc: 'esc',
  ToolbarButtonType.tab: 'tab',
  ToolbarButtonType.arrowUp: 'arrowUp',
  ToolbarButtonType.arrowDown: 'arrowDown',
  ToolbarButtonType.arrowLeft: 'arrowLeft',
  ToolbarButtonType.arrowRight: 'arrowRight',
  ToolbarButtonType.home: 'home',
  ToolbarButtonType.end: 'end',
  ToolbarButtonType.pageUp: 'pageUp',
  ToolbarButtonType.pageDown: 'pageDown',
  ToolbarButtonType.del: 'del',
  ToolbarButtonType.f1: 'f1',
  ToolbarButtonType.f2: 'f2',
  ToolbarButtonType.f3: 'f3',
  ToolbarButtonType.f4: 'f4',
  ToolbarButtonType.f5: 'f5',
  ToolbarButtonType.f6: 'f6',
  ToolbarButtonType.f7: 'f7',
  ToolbarButtonType.f8: 'f8',
  ToolbarButtonType.f9: 'f9',
  ToolbarButtonType.f10: 'f10',
  ToolbarButtonType.f11: 'f11',
  ToolbarButtonType.f12: 'f12',
  ToolbarButtonType.password: 'password',
};
