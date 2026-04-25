// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionImpl _$$SessionImplFromJson(Map<String, dynamic> json) =>
    _$SessionImpl(
      id: json['id'] as String,
      serverId: json['serverId'] as String,
      label: json['label'] as String,
      status: $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.connecting,
    );

Map<String, dynamic> _$$SessionImplToJson(_$SessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serverId': instance.serverId,
      'label': instance.label,
      'status': _$SessionStatusEnumMap[instance.status]!,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.connecting: 'connecting',
  SessionStatus.connected: 'connected',
  SessionStatus.disconnected: 'disconnected',
  SessionStatus.error: 'error',
};
