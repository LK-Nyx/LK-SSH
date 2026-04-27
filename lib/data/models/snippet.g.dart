// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snippet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SnippetImpl _$$SnippetImplFromJson(Map<String, dynamic> json) =>
    _$SnippetImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      command: json['command'] as String,
      categoryId: json['categoryId'] as String,
      requireConfirm: json['requireConfirm'] as bool? ?? false,
      autoExecute: json['autoExecute'] as bool? ?? true,
    );

Map<String, dynamic> _$$SnippetImplToJson(_$SnippetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'command': instance.command,
      'categoryId': instance.categoryId,
      'requireConfirm': instance.requireConfirm,
      'autoExecute': instance.autoExecute,
    };
