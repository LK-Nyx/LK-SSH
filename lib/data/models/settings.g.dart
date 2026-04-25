// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      keyStorageMode: $enumDecodeNullable(
              _$KeyStorageModeEnumMap, json['keyStorageMode']) ??
          KeyStorageMode.secureStorage,
      sessionTimeoutMinutes:
          (json['sessionTimeoutMinutes'] as num?)?.toInt() ?? 5,
      theme: $enumDecodeNullable(_$AppThemeEnumMap, json['theme']) ??
          AppTheme.dark,
      verboseLogging: json['verboseLogging'] as bool? ?? false,
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'keyStorageMode': _$KeyStorageModeEnumMap[instance.keyStorageMode]!,
      'sessionTimeoutMinutes': instance.sessionTimeoutMinutes,
      'theme': _$AppThemeEnumMap[instance.theme]!,
      'verboseLogging': instance.verboseLogging,
    };

const _$KeyStorageModeEnumMap = {
  KeyStorageMode.secureStorage: 'secureStorage',
  KeyStorageMode.passphraseProtected: 'passphraseProtected',
};

const _$AppThemeEnumMap = {
  AppTheme.dark: 'dark',
  AppTheme.light: 'light',
};
