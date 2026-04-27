// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SshKeyImpl _$$SshKeyImplFromJson(Map<String, dynamic> json) => _$SshKeyImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );

Map<String, dynamic> _$$SshKeyImplToJson(_$SshKeyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'addedAt': instance.addedAt.toIso8601String(),
    };
