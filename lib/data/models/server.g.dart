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
      authMethod:
          $enumDecodeNullable(_$AuthMethodEnumMap, json['authMethod']) ??
              AuthMethod.key,
      keyId: json['keyId'] as String?,
      savePassword: json['savePassword'] as bool? ?? false,
    );

Map<String, dynamic> _$$ServerImplToJson(_$ServerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'host': instance.host,
      'port': instance.port,
      'username': instance.username,
      'authMethod': _$AuthMethodEnumMap[instance.authMethod]!,
      'keyId': instance.keyId,
      'savePassword': instance.savePassword,
    };

const _$AuthMethodEnumMap = {
  AuthMethod.key: 'key',
  AuthMethod.password: 'password',
  AuthMethod.keyboardInteractive: 'keyboardInteractive',
};
