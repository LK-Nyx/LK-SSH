// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServerImpl _$$ServerImplFromJson(Map<String, dynamic> json) => _$ServerImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      host: json['host'] as String,
      port: (json['port'] as num?)?.toInt() ?? 22,
      username: json['username'] as String,
    );

Map<String, dynamic> _$$ServerImplToJson(_$ServerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'host': instance.host,
      'port': instance.port,
      'username': instance.username,
    };
